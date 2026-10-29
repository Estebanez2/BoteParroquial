import 'person.dart';
import 'year_month.dart';

enum QuotaPersonStatus { paid, partial, pending, incomplete, notApplicable }

/// Current settlement of obligations, independent of cash received in a period.
final class QuotaTotals {
  const QuotaTotals({
    required this.knownExpectedCents,
    required this.allocatedCents,
    required this.coveredCents,
    required this.knownPendingCents,
    required this.overpaidCents,
    required this.unknownMonthsCount,
  });
  final int knownExpectedCents,
      allocatedCents,
      coveredCents,
      knownPendingCents,
      overpaidCents,
      unknownMonthsCount;
  bool get isComplete => unknownMonthsCount == 0;
  int? get expectedCents => isComplete ? knownExpectedCents : null;
  int? get pendingCents => isComplete ? knownPendingCents : null;
  int? get coverageBasisPoints => !isComplete || knownExpectedCents == 0
      ? null
      : ((BigInt.from(coveredCents) * BigInt.from(10000)) ~/
                BigInt.from(knownExpectedCents))
            .toInt();
  QuotaPersonStatus get status => !isComplete
      ? QuotaPersonStatus.incomplete
      : knownExpectedCents == 0
      ? QuotaPersonStatus.notApplicable
      : knownPendingCents == 0
      ? QuotaPersonStatus.paid
      : coveredCents > 0
      ? QuotaPersonStatus.partial
      : QuotaPersonStatus.pending;
}

final class QuotaGroupSlice {
  QuotaGroupSlice({
    required this.totals,
    required Map<QuotaPersonStatus, int> people,
  }) : people = Map.unmodifiable(people);
  final QuotaTotals totals;
  final Map<QuotaPersonStatus, int> people;
  int count(QuotaPersonStatus status) => people[status] ?? 0;
}

final class PersonQuotaReport {
  const PersonQuotaReport({
    required this.person,
    required this.elapsed,
    required this.forecast,
    required this.accumulated,
    required this.unallocatedCreditCents,
    required this.futureCreditCents,
  });
  final Person person;
  final QuotaTotals elapsed, forecast, accumulated;
  final int unallocatedCreditCents, futureCreditCents;
}

final class QuotaMonthReport {
  const QuotaMonthReport({
    required this.month,
    required this.isFuture,
    required this.summary,
  });
  final YearMonth month;
  final bool isFuture;
  final QuotaGroupSlice summary;
}

final class QuotaReport {
  QuotaReport({
    required this.groupId,
    required this.firstMonth,
    required this.lastMonth,
    required this.currentMonth,
    required this.elapsed,
    required this.forecast,
    required this.accumulated,
    required Iterable<PersonQuotaReport> persons,
    required Iterable<QuotaMonthReport> months,
    required this.unallocatedCreditCents,
    required this.futureCreditCents,
  }) : persons = List.unmodifiable(persons),
       months = List.unmodifiable(months);
  final String groupId;
  final YearMonth firstMonth, lastMonth, currentMonth;
  final QuotaGroupSlice elapsed, forecast, accumulated;
  final List<PersonQuotaReport> persons;
  final List<QuotaMonthReport> months;
  final int unallocatedCreditCents, futureCreditCents;
  bool get hasForecast => lastMonth.isAfter(currentMonth);
}
