import '../core/errors/app_failure.dart';
import '../models/economic_report.dart';
import '../models/movement.dart';
import '../models/participation_period.dart';
import '../models/person.dart';
import '../models/quota_allocation.dart';
import '../models/quota_report.dart';
import '../models/quota_rule.dart';
import '../models/report_comparison.dart';
import '../models/year_month.dart';
import 'economic_report_repository.dart';
import 'quota_report_repository.dart';

/// Comparisons use the same in-memory snapshot for both sides, never a new read.
final class ReportComparisonRepository {
  const ReportComparisonRepository();

  PeriodComparison? summarize({
    required String groupId,
    required ReportSelection selection,
    required DateTime today,
    required List<Person> persons,
    required List<Movement> movements,
    required List<QuotaRule> rules,
    required List<ParticipationPeriod> periods,
    required List<QuotaAllocation> allocations,
    required QuotaReportRepository quotaRepository,
  }) {
    if (groupId.isEmpty ||
        selection.year < 2000 ||
        selection.year > 2100 ||
        selection.month < 1 ||
        selection.month > 12 ||
        today != DateTime.utc(today.year, today.month, today.day) ||
        !today.isUtc) {
      throw const AppFailure(
        FailureCode.invalidData,
        'El periodo de comparación no es válido.',
      );
    }
    final start = DateTime.utc(selection.year, selection.startMonth);
    final fullEnd = DateTime.utc(
      selection.year,
      selection.startMonth + selection.monthCount,
    );
    final previousStart = DateTime.utc(
      selection.year,
      selection.startMonth - selection.monthCount,
    );
    // Future periods and the lower domain boundary have no comparable actuals.
    if (start.isAfter(today) || previousStart.year < 2000) return null;
    final isPartial = today.isBefore(fullEnd);
    final end = isPartial ? today.add(const Duration(days: 1)) : fullEnd;
    var previousEnd = start;
    if (isPartial) {
      final shifted = DateTime.utc(
        today.year,
        today.month - selection.monthCount,
      );
      final lastDay = DateTime.utc(shifted.year, shifted.month + 1, 0).day;
      previousEnd = DateTime.utc(
        shifted.year,
        shifted.month,
        today.day < lastDay ? today.day : lastDay,
      ).add(const Duration(days: 1));
    }
    final previousSelection = ReportSelection(
      year: previousStart.year,
      month: previousStart.month,
      period: selection.period,
    );
    const economics = EconomicReportRepository();
    final currentCash = economics.summarize(
      groupId,
      movements,
      persons,
      selection,
      untilExclusive: end,
    );
    final previousCash = economics.summarize(
      groupId,
      movements,
      persons,
      previousSelection,
      untilExclusive: previousEnd,
    );
    final currentMonth = YearMonth.fromDate(today);
    QuotaTotals quotas(
      ReportSelection selected,
      DateTime from,
      DateTime until,
    ) {
      final projected = quotaRepository.summarize(
        groupId: groupId,
        currentMonth: currentMonth,
        selection: selected,
        persons: persons,
        movements: movements,
        rules: rules,
        periods: periods,
        allocations: allocations,
      );
      return QuotaReportRepository.totalsForMonths(
        projected.months.where(
          (row) =>
              !row.isFuture &&
              !row.month.firstDayUtc.isBefore(from) &&
              row.month.firstDayUtc.isBefore(until),
        ),
      );
    }

    final currentQuota = quotas(selection, start, end);
    final previousQuota = quotas(previousSelection, previousStart, previousEnd);
    ReportMetricChange change(int? current, int? previous) =>
        ReportMetricChange(current: current, previous: previous);
    int net(EconomicReport report) {
      final exact =
          BigInt.from(report.incomeCents) - BigInt.from(report.withdrawalCents);
      final value = exact.toInt();
      if (BigInt.from(value) != exact) {
        throw const AppFailure(
          FailureCode.invalidData,
          'El neto supera el intervalo admitido.',
        );
      }
      return value;
    }

    return PeriodComparison(
      selection: selection,
      currentWindow: ComparisonWindow(start: start, endExclusive: end),
      previousWindow: ComparisonWindow(
        start: previousStart,
        endExclusive: previousEnd,
      ),
      isPartial: isPartial,
      income: change(currentCash.incomeCents, previousCash.incomeCents),
      withdrawals: change(
        currentCash.withdrawalCents,
        previousCash.withdrawalCents,
      ),
      netCash: change(net(currentCash), net(previousCash)),
      expectedQuota: change(
        currentQuota.expectedCents,
        previousQuota.expectedCents,
      ),
      paidQuota: change(
        currentQuota.allocatedCents,
        previousQuota.allocatedCents,
      ),
      pendingQuota: change(
        currentQuota.pendingCents,
        previousQuota.pendingCents,
      ),
      coverage: change(
        currentQuota.coverageBasisPoints,
        previousQuota.coverageBasisPoints,
      ),
    );
  }
}
