import 'year_month.dart';

/// A historical price applies until the next rule starts. Never a mutable balance.
final class QuotaRule {
  const QuotaRule({
    required this.id,
    required this.groupId,
    required this.effectiveFrom,
    required this.monthlyFeeCents,
    this.revision = 1,
  });
  final String id, groupId;
  final YearMonth effectiveFrom;
  final int monthlyFeeCents;
  final int revision;
}
