import '../core/errors/app_failure.dart';
import '../models/movement.dart';
import '../models/monthly_balance.dart';
import '../models/year_month.dart';
import '../services/movement_trend_source.dart';
import 'balance_trend_repository.dart';
import '../models/initial_quota_assignment.dart';
import '../services/initial_quota_movement_service.dart';
import '../models/person.dart';
import '../services/movement_service.dart';
import '../services/movement_dashboard_source.dart';
import '../models/movement_cash_totals.dart';

class MovementRepository {
  const MovementRepository(this._service);
  final MovementService _service;
  static const maximumCents = 99999999999999;
  String newId(String groupId) => _service.newId(groupId);
  Future<List<MonthlyBalance>> loadBalanceTrend(
    String groupId,
    String uid,
    YearMonth currentMonth,
  ) async {
    final service = _service;
    if (service is MovementTrendSource) {
      return (service as MovementTrendSource).loadBalanceTrend(
        groupId,
        uid,
        currentMonth,
      );
    }
    return BalanceTrendRepository.calculate(
      groupId,
      await service.loadMovements(groupId),
      currentMonth,
    );
  }

  static String? initialQuotaError(
    MovementInput input,
    InitialQuotaAssignment? quota, {
    bool replacing = false,
    bool cancel = false,
  }) {
    if (quota == null) return null;
    if (cancel ||
        replacing ||
        input.type != MovementType.income ||
        input.refund != null ||
        input.personId == null ||
        quota.amountCents <= 0 ||
        quota.amountCents > input.amountCents ||
        quota.participationPeriodId.isEmpty) {
      return 'Revisa el mes y la cantidad destinada a su cuota; no puede superar el ingreso.';
    }
    return null;
  }

  Future<bool> initialQuotaApplied(
    String groupId,
    String id,
    String actorUid,
    InitialQuotaAssignment assignment,
  ) {
    final service = _service;
    if (service is! InitialQuotaMovementService) return Future.value(false);
    return (service as InitialQuotaMovementService).initialQuotaApplied(
      groupId,
      id,
      actorUid,
      assignment,
    );
  }

  Stream<List<Movement>> watchMovements(String groupId) =>
      _service.watchMovements(groupId);
  Future<List<Movement>> loadMovements(String groupId) =>
      _service.loadMovements(groupId);
  Stream<List<Movement>> watchRecent(String groupId) {
    final service = _service;
    return service is MovementDashboardSource
        ? (service as MovementDashboardSource).watchRecent(groupId)
        : service.watchMovements(groupId);
  }

  Stream<List<Movement>> watchQuotaSources(String groupId) {
    final service = _service;
    return service is MovementDashboardSource
        ? (service as MovementDashboardSource).watchQuotaSources(groupId)
        : service.watchMovements(groupId);
  }

  Future<void> clearCashAccount(String uid) async {
    final service = _service;
    if (service is MovementDashboardSource) {
      await (service as MovementDashboardSource).clearCashAccount(uid);
    }
  }

  Stream<MovementCashTotals> watchCash(
    String groupId,
    String uid,
    DateTime monthStart,
  ) {
    final service = _service;
    if (service is MovementDashboardSource) {
      return (service as MovementDashboardSource).watchCash(
        groupId,
        uid,
        monthStart,
      );
    }
    return service.watchMovements(groupId).map((rows) {
      int sum(MovementType type, bool month) {
        final total = rows
            .where(
              (m) =>
                  m.status == MovementStatus.active &&
                  m.input.type == type &&
                  (!month ||
                      (m.input.occurredAt.year == monthStart.year &&
                          m.input.occurredAt.month == monthStart.month)),
            )
            .fold<BigInt>(
              BigInt.zero,
              (acc, m) => acc + BigInt.from(m.input.amountCents),
            );
        if (BigInt.from(total.toInt()) != total) {
          throw const AppFailure(
            FailureCode.invalidData,
            'El total excede el intervalo admitido.',
          );
        }
        return total.toInt();
      }

      final value = MovementCashTotals(
        groupId: groupId,
        monthStart: monthStart,
        incomeCents: sum(MovementType.income, false),
        withdrawalCents: sum(MovementType.withdrawal, false),
        monthIncomeCents: sum(MovementType.income, true),
        monthWithdrawalCents: sum(MovementType.withdrawal, true),
        confirmedAt: DateTime.now().toUtc(),
      );
      value.validate(groupId, monthStart);
      return value;
    });
  }

  static int balanceOf(Iterable<Movement> movements) {
    final exact = movements.fold<BigInt>(
      BigInt.zero,
      (total, m) => total + BigInt.from(m.contributionCents),
    );
    if (BigInt.from(exact.toInt()) != exact) {
      throw const AppFailure(
        FailureCode.invalidData,
        'El saldo supera el intervalo admitido.',
      );
    }
    return exact.toInt();
  }

  static String? reasonError(String? value) =>
      value == null || value.trim().isEmpty
      ? 'Escribe el motivo.'
      : value.trim().length > 2000
      ? 'El motivo admite hasta 2000 caracteres.'
      : null;
  static String? inputError(MovementInput input, {DateTime? today}) {
    final refund = input.refund;
    if (refund != null &&
        (input.type != MovementType.withdrawal ||
            input.personId == null ||
            refund.amountCents != input.amountCents ||
            refund.parts.length > 4 ||
            refund.unallocatedCents < 0 ||
            refund.parts.any((p) => p.amountCents <= 0) ||
            refund.parts.map((p) => p.month).toSet().length !=
                refund.parts.length)) {
      return 'Revisa el reparto de la devolución: un ingreso y hasta cuatro meses.';
    }
    if (input.amountCents <= 0 || input.amountCents > maximumCents) {
      return 'Introduce una cantidad mayor que cero y dentro del límite admitido.';
    }
    if (input.type == MovementType.income &&
        (input.personId?.isEmpty ?? true)) {
      return 'Selecciona la persona del ingreso.';
    }
    if (input.description.trim().length > 2000) {
      return 'La descripción admite hasta 2000 caracteres.';
    }
    if (input.type == MovementType.withdrawal &&
        input.description.trim().isEmpty) {
      return 'Escribe el motivo de la retirada.';
    }
    if (input.occurredAt.year < 2000 || input.occurredAt.year > 2100) {
      return 'Selecciona una fecha entre 2000 y 2100.';
    }
    final now = today ?? DateTime.now();
    if (DateTime.utc(
      input.occurredAt.year,
      input.occurredAt.month,
      input.occurredAt.day,
    ).isAfter(DateTime.utc(now.year, now.month, now.day))) {
      return 'La fecha efectiva debe ser hoy o un día anterior.';
    }
    return null;
  }

  static void _checkScope(String groupId, Movement movement) {
    if (movement.groupId != groupId) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'El movimiento pertenece a otro grupo.',
      );
    }
  }

  Future<MovementReview> review(
    String groupId,
    MovementInput? input,
    List<Person> persons, {
    Movement? original,
    bool cancel = false,
    String? reason,
    String? operationId,
    String? actorUid,
    DateTime? today,
  }) async {
    if (original != null) _checkScope(groupId, original);
    final error = input == null ? null : inputError(input, today: today);
    if (error != null) throw AppFailure(FailureCode.invalidData, error);
    if (original != null) {
      final reasonFailure = reasonError(reason);
      if (reasonFailure != null) {
        throw AppFailure(FailureCode.invalidData, reasonFailure);
      }
    }
    Person? selected;
    if (input?.personId != null) {
      for (final person in persons) {
        if (person.groupId == groupId && person.id == input?.personId) {
          selected = person;
        }
      }
      if (selected == null) {
        throw const AppFailure(
          FailureCode.invalidData,
          'La persona ya no está disponible en este grupo.',
        );
      }
    }
    final movements = await _service.loadMovements(groupId);
    final balance = balanceOf(movements);
    Movement? previousSubmission;
    for (final movement in movements) {
      if (movement.id == operationId) previousSubmission = movement;
    }
    if (!cancel && previousSubmission != null && input != null) {
      final saved = previousSubmission.input;
      final same =
          previousSubmission.createdBy == actorUid &&
          saved.type == input.type &&
          saved.amountCents == input.amountCents &&
          saved.personId == input.personId &&
          saved.description == input.description.trim() &&
          (saved.refund == null
              ? input.refund == null
              : saved.refund!.sameAs(input.refund)) &&
          saved.occurredAt ==
              DateTime.utc(
                input.occurredAt.year,
                input.occurredAt.month,
                input.occurredAt.day,
              ) &&
          previousSubmission.correctionOfMovementId == original?.id;
      if (!same) {
        throw const AppFailure(
          FailureCode.invalidData,
          'Este envío ya está registrado con otros datos. Revisa el historial.',
        );
      }
      return MovementReview(
        balanceCents: balance,
        projectedCents: balance,
        inactivePerson: selected?.isActive == false,
      );
    }
    Movement? current;
    if (original != null) {
      if (original.input.type == MovementType.income &&
          movements.any(
            (m) =>
                m.status == MovementStatus.active &&
                m.input.refund?.incomeId == original.id,
          )) {
        throw const AppFailure(
          FailureCode.invalidData,
          'Este ingreso tiene devoluciones activas. Anúlalas o revísalas antes de anular o corregir su origen.',
        );
      }
      for (final movement in movements) {
        if (movement.id == original.id) current = movement;
      }
      if (cancel &&
          current?.status == MovementStatus.cancelled &&
          current?.cancelledBy == actorUid &&
          current?.cancellationReason == reason?.trim()) {
        return MovementReview(
          balanceCents: balance,
          projectedCents: balance,
          inactivePerson: false,
        );
      }
      if (current == null ||
          current.status != MovementStatus.active ||
          current.updatedAt != original.updatedAt) {
        throw const AppFailure(
          FailureCode.invalidData,
          'El movimiento ha cambiado. Vuelve al historial para actualizarlo.',
        );
      }
    }
    return MovementReview(
      balanceCents: balance,
      projectedCents:
          balance -
          (current?.contributionCents ?? 0) +
          (cancel ? 0 : input?.signedCents ?? 0),
      inactivePerson: selected?.isActive == false,
    );
  }

  Future<void> save(
    String groupId,
    String id,
    String actorUid,
    MovementInput input, {
    Movement? original,
    String? reason,
    DateTime? today,
    InitialQuotaAssignment? initialQuota,
  }) {
    final error =
        inputError(input, today: today) ??
        (original == null ? null : reasonError(reason));
    if (error != null) throw AppFailure(FailureCode.invalidData, error);
    if (original != null) _checkScope(groupId, original);
    final normalized = MovementInput(
      type: input.type,
      amountCents: input.amountCents,
      occurredAt: DateTime.utc(
        input.occurredAt.year,
        input.occurredAt.month,
        input.occurredAt.day,
      ),
      description: input.description.trim(),
      personId: input.personId,
      refund: input.refund,
    );
    if (initialQuota != null) {
      final quotaError = initialQuotaError(
        normalized,
        initialQuota,
        replacing: original != null,
      );
      if (quotaError != null) {
        throw AppFailure(FailureCode.invalidData, quotaError);
      }
      final service = _service;
      if (service is! InitialQuotaMovementService) {
        throw const AppFailure(
          FailureCode.configuration,
          'El guardado conjunto no está disponible. No se ha enviado el ingreso.',
        );
      }
      return (service as InitialQuotaMovementService).saveWithInitialQuota(
        groupId,
        id,
        actorUid,
        normalized,
        initialQuota,
      );
    }
    return _service.save(
      groupId,
      id,
      actorUid,
      normalized,
      original: original,
      reason: reason?.trim(),
    );
  }

  Future<void> cancel(
    String groupId,
    Movement movement,
    String actorUid,
    String reason,
  ) {
    _checkScope(groupId, movement);
    final error = reasonError(reason);
    if (error != null) throw AppFailure(FailureCode.invalidData, error);
    return _service.cancel(groupId, movement, actorUid, reason.trim());
  }
}
