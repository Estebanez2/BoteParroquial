import '../core/errors/app_failure.dart';
import '../models/movement.dart';
import '../models/participation_period.dart';
import '../models/quota_allocation.dart';
import '../models/quota_expectation.dart';
import '../models/quota_rule.dart';
import '../models/quota_settlement.dart';
import '../models/year_month.dart';
import 'quota_expectation_repository.dart';

/// Pure projection: the pot balance is deliberately independent of allocations.
final class QuotaSettlementRepository {
  const QuotaSettlementRepository();
  static const invalid = AppFailure(
    FailureCode.invalidData,
    'Las asignaciones no coinciden con sus ingresos. Actualiza la ficha antes de continuar.',
  );

  PersonQuotaSettlement summarize({
    required String groupId,
    required String personId,
    required YearMonth currentMonth,
    required List<QuotaRule> rules,
    required List<ParticipationPeriod> periods,
    required List<Movement> movements,
    required List<QuotaAllocation> allocations,
    YearMonth? includeFromMonth,
    YearMonth? includeUntilMonth,
  }) {
    final sources = <String, Movement>{};
    for (final movement in movements) {
      if (movement.groupId != groupId || sources.containsKey(movement.id)) {
        throw invalid;
      }
      sources[movement.id] = movement;
    }
    final byIncome = <String, int>{}, byMonth = <YearMonth, int>{};
    final refunded = <String, int>{};
    final refundedAssigned = <String, int>{},
        refundedByAllocation = <String, int>{};
    for (final movement in movements) {
      final refund = movement.input.refund;
      if (movement.status != MovementStatus.active || refund == null) continue;
      final income = sources[refund.incomeId];
      if (income == null ||
          income.status != MovementStatus.active ||
          income.input.type != MovementType.income ||
          income.input.personId != movement.input.personId ||
          movement.input.amountCents != refund.amountCents) {
        throw invalid;
      }
      refunded.update(
        income.id,
        (v) => v + refund.amountCents,
        ifAbsent: () => refund.amountCents,
      );
      refundedAssigned.update(
        income.id,
        (v) => v + refund.assignedCents,
        ifAbsent: () => refund.assignedCents,
      );
      for (final part in refund.parts) {
        final key = '${income.id}/${part.month.ordinal}';
        refundedByAllocation.update(
          key,
          (v) => v + part.amountCents,
          ifAbsent: () => part.amountCents,
        );
      }
    }
    final pairs = <String>{};
    var first = currentMonth;
    var last = currentMonth.ordinal + 12 <= YearMonth(2100, 12).ordinal
        ? currentMonth.addMonths(12)
        : YearMonth(2100, 12);
    if (includeFromMonth != null &&
        includeUntilMonth != null &&
        includeFromMonth.isAfter(includeUntilMonth)) {
      throw invalid;
    }
    if (includeFromMonth != null && includeFromMonth.isBefore(first)) {
      first = includeFromMonth;
    }
    if (includeUntilMonth != null && includeUntilMonth.isAfter(last)) {
      last = includeUntilMonth;
    }
    for (final period in periods) {
      if (period.firstMonth.isBefore(first)) first = period.firstMonth;
    }
    for (final allocation in allocations) {
      final source = sources[allocation.movementId];
      if (allocation.groupId != groupId ||
          allocation.personId != personId ||
          allocation.amountCents < 0 ||
          allocation.amountCents > 99999999999999 ||
          allocation.revision < 1 ||
          source == null ||
          source.input.type != MovementType.income ||
          source.input.personId != personId ||
          !pairs.add('${allocation.movementId}/${allocation.month}')) {
        throw invalid;
      }
      byIncome.update(
        source.id,
        (v) => v + allocation.amountCents,
        ifAbsent: () => allocation.amountCents,
      );
      if (byIncome[source.id]! > source.input.amountCents) throw invalid;
      if (source.status != MovementStatus.active) continue;
      final returned =
          refundedByAllocation['${source.id}/${allocation.month.ordinal}'] ?? 0;
      if (returned > allocation.amountCents) throw invalid;
      final net = allocation.amountCents - returned;
      byMonth.update(allocation.month, (v) => v + net, ifAbsent: () => net);
      if (allocation.month.isBefore(first)) first = allocation.month;
      if (allocation.month.isAfter(last)) last = allocation.month;
    }
    for (final entry in refundedByAllocation.entries) {
      final incomeId = entry.key.split('/').first;
      if (sources[incomeId]?.input.personId == personId &&
          !allocations.any(
            (a) => '${a.movementId}/${a.month.ordinal}' == entry.key,
          )) {
        throw invalid;
      }
    }
    final expectation = const QuotaExpectationRepository().summarize(
      groupId: groupId,
      personId: personId,
      firstMonth: first,
      lastMonth: last,
      rules: rules,
      periods: periods,
    );
    final rows = <MonthQuotaPayment>[];
    var expected = 0, paid = 0, future = 0, pending = 0;
    var complete = true;
    for (final row in expectation.months) {
      final assigned = byMonth[row.month] ?? 0;
      final isFuture = row.month.isAfter(currentMonth);
      final due = row.expectedCents;
      final state = switch (row.state) {
        QuotaExpectationState.participationNotConfigured ||
        QuotaExpectationState.missingRule => QuotaPaymentState.incomplete,
        QuotaExpectationState.notApplicable => QuotaPaymentState.notApplicable,
        QuotaExpectationState.priced =>
          assigned > due!
              ? QuotaPaymentState.overpaid
              : due == 0
              ? QuotaPaymentState.suspended
              : assigned == due
              ? QuotaPaymentState.paid
              : assigned == 0
              ? QuotaPaymentState.pending
              : QuotaPaymentState.partial,
      };
      final remaining = due == null
          ? null
          : (due > assigned ? due - assigned : 0);
      rows.add(
        MonthQuotaPayment(
          expectation: row,
          allocatedCents: assigned,
          isFuture: isFuture,
          state: state,
          pendingCents: remaining,
        ),
      );
      if (isFuture) {
        future += assigned;
      } else {
        expected += due ?? 0;
        paid += assigned;
        pending += remaining ?? 0;
        if (due == null) complete = false;
      }
    }
    final incomes =
        sources.values
            .where(
              (m) =>
                  m.status == MovementStatus.active &&
                  m.input.type == MovementType.income &&
                  m.input.personId == personId,
            )
            .map(
              (m) => IncomeQuotaBalance(
                movement: m,
                allocatedCents: byIncome[m.id] ?? 0,
                refundedCents: refunded[m.id] ?? 0,
                refundedAssignedCents: refundedAssigned[m.id] ?? 0,
              ),
            )
            .toList()
          ..sort(
            (a, b) => b.movement.input.occurredAt.compareTo(
              a.movement.input.occurredAt,
            ),
          );
    if (incomes.any((i) => i.unallocatedCents < 0)) throw invalid;
    return PersonQuotaSettlement(
      months: rows,
      incomes: incomes,
      isComplete: complete,
      currentMonth: currentMonth,
      refundedByAllocation: refundedByAllocation,
      knownExpectedCents: expected,
      allocatedThroughCurrentCents: paid,
      futureCreditCents: future,
      unallocatedCreditCents: incomes.fold(
        0,
        (sum, income) => sum + income.unallocatedCents,
      ),
      pendingCents: complete ? pending : null,
    );
  }

  /// Only proposes unused cents. No write and no automatic historical migration.
  List<AllocationSuggestion> propose(
    PersonQuotaSettlement settlement,
    Movement income,
    List<QuotaAllocation> allocations,
  ) {
    if (!settlement.isComplete) return const [];
    final source = settlement.incomes
        .where((i) => i.movement.id == income.id)
        .firstOrNull;
    if (source == null) return const [];
    var available = source.unallocatedCents;
    final result = <AllocationSuggestion>[];
    for (final row in settlement.months) {
      if (available == 0) break;
      if (row.month.ordinal > settlement.currentMonth.ordinal + 12) break;
      // An unknown participating month blocks guessing payments beyond it.
      if (row.state == QuotaPaymentState.incomplete) break;
      final pending = row.pendingCents ?? 0;
      if (pending == 0) continue;
      final amount = available < pending ? available : pending;
      final previous = allocations
          .where((a) => a.movementId == income.id && a.month == row.month)
          .firstOrNull;
      result.add(
        AllocationSuggestion(
          month: row.month,
          amountCents: (previous?.amountCents ?? 0) + amount,
        ),
      );
      available -= amount;
    }
    return List.unmodifiable(result);
  }
}
