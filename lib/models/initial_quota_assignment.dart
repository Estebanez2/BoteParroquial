import 'year_month.dart';

/// Optional explicit quota payment, committed with a newly received income.
final class InitialQuotaAssignment {
  const InitialQuotaAssignment({
    required this.month,
    required this.amountCents,
    required this.participationPeriodId,
  });
  final YearMonth month;
  final int amountCents;
  final String participationPeriodId;
  Map<String, Object> toMap() => {
    'month': month.toString(),
    'amountCents': amountCents,
    'participationPeriodId': participationPeriodId,
  };
  factory InitialQuotaAssignment.fromMap(Map<String, dynamic> value) =>
      InitialQuotaAssignment(
        month: YearMonth.parse(value['month'] as String),
        amountCents: value['amountCents'] as int,
        participationPeriodId: value['participationPeriodId'] as String,
      );
  @override
  bool operator ==(Object other) =>
      other is InitialQuotaAssignment &&
      month == other.month &&
      amountCents == other.amountCents &&
      participationPeriodId == other.participationPeriodId;
  @override
  int get hashCode => Object.hash(month, amountCents, participationPeriodId);
}
