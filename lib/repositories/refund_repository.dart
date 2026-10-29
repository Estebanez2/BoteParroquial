import '../core/errors/app_failure.dart';
import '../models/movement.dart';
import '../models/quota_allocation.dart';
import '../models/quota_settlement.dart';
import '../models/refund_plan.dart';
import '../models/refund_source.dart';
import '../models/year_month.dart';

final class RefundRepository {
  const RefundRepository();
  static const _invalid = AppFailure(
    FailureCode.invalidData,
    'Actualiza el ingreso y revisa su devolución antes de continuar.',
  );
  RefundSource source({
    required String groupId,
    required String incomeId,
    required PersonQuotaSettlement settlement,
    required List<Movement> movements,
    required List<QuotaAllocation> allocations,
    String? originalId,
  }) {
    final income = settlement.incomes
        .where((i) => i.movement.id == incomeId)
        .firstOrNull;
    final original = movements.where((m) => m.id == originalId).firstOrNull;
    if (income == null ||
        income.movement.groupId != groupId ||
        (originalId != null &&
            (original == null ||
                original.groupId != groupId ||
                original.status != MovementStatus.active ||
                original.input.refund?.incomeId != incomeId))) {
      throw _invalid;
    }
    final old = original?.input.refund;
    final months = <RefundableMonth>[];
    for (final row in allocations.where((a) => a.movementId == incomeId)) {
      if (row.groupId != groupId ||
          row.personId != income.movement.input.personId) {
        throw _invalid;
      }
      final available =
          row.amountCents -
          settlement.refundedFor(incomeId, row.month) +
          (old?.atMonth(row.month) ?? 0);
      if (available > 0) {
        months.add(
          RefundableMonth(month: row.month, availableCents: available),
        );
      }
    }
    months.sort((a, b) => a.month.compareTo(b.month));
    return RefundSource(
      income: income.movement,
      original: original,
      unallocatedCents: income.unallocatedCents + (old?.unallocatedCents ?? 0),
      months: months,
    );
  }

  MovementInput prepare({
    required RefundSource source,
    required Map<YearMonth, int?> selected,
    required int? unallocatedCents,
    required DateTime occurredAt,
    required String description,
  }) {
    if (unallocatedCents == null ||
        unallocatedCents < 0 ||
        unallocatedCents > source.unallocatedCents ||
        selected.values.any((c) => c == null || c < 0)) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Revisa las cantidades: no pueden superar el crédito o el pago disponible.',
      );
    }
    final parts = <RefundPart>[];
    for (final entry in selected.entries) {
      final cents = entry.value!;
      if (cents == 0) continue;
      final candidate = source.months
          .where((m) => m.month == entry.key)
          .firstOrNull;
      if (candidate == null || cents > candidate.availableCents) {
        throw const AppFailure(
          FailureCode.invalidData,
          'No puedes devolver más de lo que queda pagado en ese mes.',
        );
      }
      parts.add(RefundPart(month: entry.key, amountCents: cents));
    }
    final affected = {
      ...parts.map((p) => p.month),
      ...?source.original?.input.refund?.parts.map((p) => p.month),
    };
    if (affected.length > 4) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Cada devolución puede afectar hasta cuatro meses distintos. Al corregir, también cuentan los meses del original. Puedes anularla y registrar otra.',
      );
    }
    final plan = RefundPlan(
      incomeId: source.income.id,
      unallocatedCents: unallocatedCents,
      parts: parts,
    );
    if (plan.amountCents <= 0 || plan.amountCents > 99999999999999) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Indica cuánto quieres devolver, en cuotas o crédito sin asignar.',
      );
    }
    final date = DateTime.utc(
      occurredAt.year,
      occurredAt.month,
      occurredAt.day,
    );
    if (date.isBefore(source.income.input.occurredAt)) {
      throw const AppFailure(
        FailureCode.invalidData,
        'La devolución no puede tener una fecha anterior al ingreso de origen.',
      );
    }
    return MovementInput(
      type: MovementType.withdrawal,
      amountCents: plan.amountCents,
      occurredAt: date,
      description: description,
      personId: source.income.input.personId,
      refund: plan,
    );
  }
}
