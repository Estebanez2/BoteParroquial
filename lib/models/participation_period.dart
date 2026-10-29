import 'year_month.dart';

/// Explicit computable months; metadata/active status do not infer this history.
final class ParticipationPeriod implements Comparable<ParticipationPeriod> {
  const ParticipationPeriod({
    required this.id,
    required this.groupId,
    required this.personId,
    required this.firstMonth,
    this.lastMonthInclusive,
  });
  final String id, groupId, personId;
  final YearMonth firstMonth;
  final YearMonth? lastMonthInclusive;
  bool includes(YearMonth month) =>
      !month.isBefore(firstMonth) &&
      (lastMonthInclusive == null || !month.isAfter(lastMonthInclusive!));
  @override
  int compareTo(ParticipationPeriod other) {
    final first = firstMonth.compareTo(other.firstMonth);
    if (first != 0) return first;
    final end = (lastMonthInclusive?.ordinal ?? 25212).compareTo(
      other.lastMonthInclusive?.ordinal ?? 25212,
    );
    return end != 0 ? end : id.compareTo(other.id);
  }
}
