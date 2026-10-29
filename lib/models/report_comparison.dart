import 'economic_report.dart';

/// A civil date range, with an exclusive end, in the group's calendar.
final class ComparisonWindow {
  const ComparisonWindow({required this.start, required this.endExclusive});
  final DateTime start, endExclusive;
}

/// Null values preserve incomplete quota configuration. Ratios never use floats.
final class ReportMetricChange {
  ReportMetricChange({required this.current, required this.previous}) {
    final a = current, b = previous;
    if (a != null && b != null) {
      final exact = BigInt.from(a) - BigInt.from(b);
      final value = exact.toInt();
      if (BigInt.from(value) != exact) {
        throw ArgumentError('La diferencia supera el intervalo admitido.');
      }
      difference = value;
    } else {
      difference = null;
    }
  }
  final int? current, previous;
  late final int? difference;

  /// A zero or negative baseline has no meaningful relative percentage.
  BigInt? get relativeChangeBasisPoints {
    final base = previous, delta = difference;
    if (base == null || base <= 0 || delta == null) return null;
    return (BigInt.from(delta) * BigInt.from(10000)) ~/ BigInt.from(base);
  }
}

final class PeriodComparison {
  const PeriodComparison({
    required this.selection,
    required this.currentWindow,
    required this.previousWindow,
    required this.isPartial,
    required this.income,
    required this.withdrawals,
    required this.netCash,
    required this.expectedQuota,
    required this.paidQuota,
    required this.pendingQuota,
    required this.coverage,
  });
  final ReportSelection selection;
  final ComparisonWindow currentWindow, previousWindow;
  final bool isPartial;
  final ReportMetricChange income, withdrawals, netCash;
  final ReportMetricChange expectedQuota, paidQuota, pendingQuota;

  /// Values are basis points; their difference is percentage points, not growth.
  final ReportMetricChange coverage;
}
