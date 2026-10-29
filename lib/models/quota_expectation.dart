import 'year_month.dart';

enum QuotaExpectationState {
  participationNotConfigured,
  notApplicable,
  missingRule,
  priced,
}

final class MonthQuotaExpectation {
  const MonthQuotaExpectation({
    required this.month,
    required this.state,
    required this.expectedCents,
    required this.ruleId,
  });
  final YearMonth month;
  final QuotaExpectationState state;

  /// Null means participation or price is unknown, never an inferred zero debt.
  final int? expectedCents;
  final String? ruleId;
}

final class PersonQuotaExpectation {
  PersonQuotaExpectation({required List<MonthQuotaExpectation> months})
    : months = List.unmodifiable(months);
  final List<MonthQuotaExpectation> months;
  bool get isComplete => months.every(
    (m) =>
        m.state != QuotaExpectationState.missingRule &&
        m.state != QuotaExpectationState.participationNotConfigured,
  );

  /// Sum of priced months, not a debt, paid balance or allocation projection.
  int get knownExpectedCents =>
      months.fold(0, (sum, row) => sum + (row.expectedCents ?? 0));
}
