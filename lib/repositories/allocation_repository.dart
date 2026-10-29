import '../core/errors/app_failure.dart';
import '../models/movement.dart';
import '../models/participation_period.dart';
import '../models/quota_allocation.dart';
import '../models/quota_settlement.dart';
import '../models/quota_rule.dart';
import '../models/year_month.dart';
import '../services/allocation_service.dart';
import 'quota_repository.dart';

final class AllocationRepository {
  const AllocationRepository(this._service);
  final AllocationService _service;
  String newOperationId(String groupId) => _service.newOperationId(groupId);
  Stream<List<QuotaAllocation>> watchAllocations(
    String groupId,
    String personId,
  ) => _service.watchAllocations(groupId, personId);
  static const _invalid = AppFailure(
    FailureCode.invalidData,
    'Revisa el ingreso, el mes y la cantidad antes de asignar.',
  );

  AllocationReview review({
    required String groupId,
    required String operationId,
    required String actorUid,
    required Movement movement,
    required YearMonth month,
    required int? cents,
    required PersonQuotaSettlement settlement,
    required List<QuotaAllocation> allocations,
    required List<ParticipationPeriod> periods,
    required List<QuotaRule> rules,
  }) {
    if (movement.groupId != groupId ||
        movement.status != MovementStatus.active ||
        movement.input.type != MovementType.income ||
        movement.input.personId == null ||
        cents == null ||
        cents < 0 ||
        cents > 99999999999999) {
      throw _invalid;
    }
    final personId = movement.input.personId;
    if (cents < settlement.refundedFor(movement.id, month)) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Este reparto conserva dinero ya devuelto. Anula o corrige primero la devolución para reducirlo.',
      );
    }
    if (allocations.any(
          (a) => a.groupId != groupId || a.personId != personId,
        ) ||
        periods.any((p) => p.groupId != groupId || p.personId != personId) ||
        rules.any((r) => r.groupId != groupId)) {
      throw _invalid;
    }
    final previous = allocations
        .where((a) => a.movementId == movement.id && a.month == month)
        .firstOrNull;
    final source = settlement.incomes
        .where((i) => i.movement.id == movement.id)
        .firstOrNull;
    if (source == null ||
        cents > source.unallocatedCents + (previous?.amountCents ?? 0)) {
      throw const AppFailure(
        FailureCode.invalidData,
        'El reparto no puede superar el importe del ingreso. Libera primero lo asignado a otros meses.',
      );
    }
    if (cents == (previous?.amountCents ?? 0)) {
      throw const AppFailure(
        FailureCode.invalidData,
        'La cantidad de ese mes no ha cambiado.',
      );
    }
    final period = periods.where((p) => p.includes(month)).firstOrNull;
    if (cents > 0 && period == null) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Elige un mes incluido en una etapa de participación de esta persona.',
      );
    }
    final row = settlement.months.where((m) => m.month == month).firstOrNull;
    final expected = period == null
        ? 0
        : QuotaRepository.atMonth(rules, month)?.monthlyFeeCents;
    final projected =
        (row?.allocatedCents ?? 0) - (previous?.amountCents ?? 0) + cents;
    return AllocationReview(
      change: AllocationChange(
        operationId: operationId,
        actorUid: actorUid,
        movement: movement,
        month: month,
        amountCents: cents,
        previous: previous,
        participationPeriodId: period?.id ?? previous!.participationPeriodId,
      ),
      overpaymentCents: expected == null || projected <= expected
          ? 0
          : projected - expected,
      expectedCents: expected,
    );
  }

  Future<void> change(
    String groupId,
    String actorUid,
    AllocationChange change,
  ) {
    if (change.movement.groupId != groupId ||
        actorUid != change.actorUid ||
        actorUid.isEmpty ||
        change.operationId.isEmpty) {
      throw _invalid;
    }
    return _service.change(groupId, actorUid, change);
  }
}
