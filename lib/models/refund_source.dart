import 'movement.dart';
import 'year_month.dart';

final class RefundableMonth {
  const RefundableMonth({required this.month, required this.availableCents});
  final YearMonth month;
  final int availableCents;
}

final class RefundSource {
  RefundSource({
    required this.income,
    required this.original,
    required this.unallocatedCents,
    required Iterable<RefundableMonth> months,
  }) : months = List.unmodifiable(months);
  final Movement income;
  final Movement? original;
  final int unallocatedCents;
  final List<RefundableMonth> months;
}
