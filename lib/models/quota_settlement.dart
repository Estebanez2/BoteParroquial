import 'movement.dart';
import 'quota_expectation.dart';
import 'quota_allocation.dart';
import 'year_month.dart';

enum QuotaPaymentState {
  incomplete,
  notApplicable,
  suspended,
  pending,
  partial,
  paid,
  overpaid,
}

final class MonthQuotaPayment {
  const MonthQuotaPayment({
    required this.expectation,
    required this.allocatedCents,
    required this.isFuture,
    required this.state,
    required this.pendingCents,
  });
  final MonthQuotaExpectation expectation;
  YearMonth get month => expectation.month;
  final int allocatedCents;
  final bool isFuture;
  final QuotaPaymentState state;
  final int? pendingCents;
}

final class IncomeQuotaBalance {
  const IncomeQuotaBalance({
    required this.movement,
    required this.allocatedCents,
    this.refundedCents = 0,
    this.refundedAssignedCents = 0,
  });
  final Movement movement;
  final int allocatedCents;
  final int refundedCents;
  final int refundedAssignedCents;
  int get paidCents => allocatedCents - refundedAssignedCents;
  int get unallocatedCents =>
      movement.input.amountCents -
      allocatedCents -
      refundedCents +
      refundedAssignedCents;
}

final class PersonQuotaSettlement {
  PersonQuotaSettlement({
    required Iterable<MonthQuotaPayment> months,
    required Iterable<IncomeQuotaBalance> incomes,
    required this.isComplete,
    required this.knownExpectedCents,
    required this.allocatedThroughCurrentCents,
    required this.futureCreditCents,
    required this.unallocatedCreditCents,
    required this.pendingCents,
    required this.currentMonth,
    Map<String, int> refundedByAllocation = const {},
  }) : months = List.unmodifiable(months),
       refundedByAllocation = Map.unmodifiable(refundedByAllocation),
       incomes = List.unmodifiable(incomes);
  final List<MonthQuotaPayment> months;
  final List<IncomeQuotaBalance> incomes;
  final bool isComplete;
  final YearMonth currentMonth;
  final Map<String, int> refundedByAllocation;
  int refundedFor(String incomeId, YearMonth month) =>
      refundedByAllocation['$incomeId/${month.ordinal}'] ?? 0;
  final int knownExpectedCents, allocatedThroughCurrentCents;
  final int futureCreditCents, unallocatedCreditCents;

  /// Unknown configuration must never be presented as zero debt.
  final int? pendingCents;
  int? get differenceCents =>
      isComplete ? allocatedThroughCurrentCents - knownExpectedCents : null;
}

final class IncomeAllocationView {
  IncomeAllocationView({
    required this.movement,
    required this.settlement,
    required Iterable<QuotaAllocation> allocations,
    required Iterable<AllocationSuggestion> suggestions,
  }) : allocations = List.unmodifiable(allocations),
       suggestions = List.unmodifiable(suggestions);
  final Movement movement;
  final PersonQuotaSettlement settlement;
  final List<QuotaAllocation> allocations;
  final List<AllocationSuggestion> suggestions;
  bool get canAllocate => movement.status == MovementStatus.active;
  int get assignedCents => allocations.fold(0, (sum, a) => sum + a.amountCents);
  IncomeQuotaBalance? get _balance =>
      settlement.incomes.where((i) => i.movement.id == movement.id).firstOrNull;
  int get refundedCents => _balance?.refundedCents ?? 0;
  int get paidCents => assignedCents - (_balance?.refundedAssignedCents ?? 0);
  int get availableCents =>
      settlement.incomes
          .where((i) => i.movement.id == movement.id)
          .firstOrNull
          ?.unallocatedCents ??
      0;
}
