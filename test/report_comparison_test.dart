import 'package:flutter_test/flutter_test.dart';
import 'package:bote_parroquial/models/report_comparison.dart';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/models/economic_report.dart';
import 'package:bote_parroquial/models/movement.dart';
import 'package:bote_parroquial/repositories/economic_report_repository.dart';
import 'package:bote_parroquial/repositories/quota_report_repository.dart';
import 'package:bote_parroquial/repositories/report_comparison_repository.dart';
import 'quota_reports_test.dart' as fixtures;
import 'quota_allocations_test.dart' as quotas;

void main() {
  final service = fixtures.MemoryGroupQuotas();
  final quotaRepository = QuotaReportRepository(service);
  tearDownAll(() => service.changes.close());
  PeriodComparison? compare(
    ReportSelection selection,
    DateTime today, {
    List<Movement>? movements,
    bool configured = true,
  }) => const ReportComparisonRepository().summarize(
    groupId: 'a',
    selection: selection,
    today: today,
    persons: configured
        ? fixtures.people
        : [...fixtures.people, fixtures.person('r')],
    movements: movements ?? fixtures.money,
    rules: quotas.rules,
    periods: fixtures.periods,
    allocations: fixtures.allocations,
    quotaRepository: quotaRepository,
  );
  test(
    'Diferencias exactas sin dividir por cero ni convertir desconocidos en cero',
    () {
      final growth = ReportMetricChange(current: 1500, previous: 1000);
      expect(growth.difference, 500);
      expect(growth.relativeChangeBasisPoints, BigInt.from(5000));
      final decline = ReportMetricChange(current: 0, previous: 1000);
      expect(decline.relativeChangeBasisPoints, BigInt.from(-10000));
      for (final previous in [0, -1000, null]) {
        expect(
          ReportMetricChange(
            current: 1000,
            previous: previous,
          ).relativeChangeBasisPoints,
          isNull,
        );
      }
      expect(
        ReportMetricChange(current: null, previous: 1000).difference,
        isNull,
      );
      expect(
        ReportMetricChange(
          current: 900000000000000000,
          previous: 1,
        ).relativeChangeBasisPoints,
        (BigInt.parse('900000000000000000') - BigInt.one) * BigInt.from(10000),
      );
    },
  );

  test(
    'Mes, trimestre y año respetan tramos civiles, bisiestos y frontera del dominio',
    () {
      for (final entry in [
        (
          const ReportSelection(year: 2026, month: 3),
          DateTime.utc(2026, 3, 31),
          DateTime.utc(2026, 2, 1),
          DateTime.utc(2026, 3, 1),
        ),
        (
          const ReportSelection(year: 2024, month: 3),
          DateTime.utc(2024, 3, 31),
          DateTime.utc(2024, 2, 1),
          DateTime.utc(2024, 3, 1),
        ),
        (
          const ReportSelection(
            year: 2024,
            month: 2,
            period: ReportPeriod.year,
          ),
          DateTime.utc(2024, 2, 29),
          DateTime.utc(2023, 1, 1),
          DateTime.utc(2023, 3, 1),
        ),
        (
          const ReportSelection(
            year: 2026,
            month: 10,
            period: ReportPeriod.quarter,
          ),
          DateTime.utc(2026, 10, 20),
          DateTime.utc(2026, 7, 1),
          DateTime.utc(2026, 7, 21),
        ),
        (
          const ReportSelection(
            year: 2026,
            month: 2,
            period: ReportPeriod.quarter,
          ),
          DateTime.utc(2026, 2, 15),
          DateTime.utc(2025, 10, 1),
          DateTime.utc(2025, 11, 16),
        ),
      ]) {
        final value = compare(entry.$1, entry.$2)!;
        expect(value.previousWindow.start, entry.$3);
        expect(value.previousWindow.endExclusive, entry.$4);
        expect(
          value.currentWindow.endExclusive,
          entry.$2.add(const Duration(days: 1)),
        );
      }
      final full = compare(
        const ReportSelection(
          year: 2026,
          month: 6,
          period: ReportPeriod.quarter,
        ),
        DateTime.utc(2026, 10, 20),
      )!;
      expect(full.isPartial, false);
      expect(full.currentWindow.start, DateTime.utc(2026, 4));
      expect(full.currentWindow.endExclusive, DateTime.utc(2026, 7));
      expect(full.previousWindow.endExclusive, DateTime.utc(2026, 4));
      expect(
        compare(
          const ReportSelection(year: 2026, month: 12),
          DateTime.utc(2026, 10, 20),
        ),
        isNull,
      );
      expect(
        compare(
          const ReportSelection(year: 2000, month: 1),
          DateTime.utc(2026, 10, 20),
        ),
        isNull,
      );
    },
  );

  test(
    'Compara caja efectiva y cuotas actualizadas sin incluir días posteriores, futuros o anulados',
    () {
      const selection = ReportSelection(year: 2026, month: 6);
      final money = [
        ...fixtures.money,
        fixtures.income('late-may', 'p', 700, date: DateTime.utc(2026, 5, 30)),
        fixtures.income(
          'later-june',
          'p',
          800,
          date: DateTime.utc(2026, 6, 20),
        ),
        fixtures.income(
          'cancelled',
          'p',
          900,
          status: MovementStatus.cancelled,
        ),
      ];
      final value = compare(
        selection,
        DateTime.utc(2026, 6, 15),
        movements: money,
      )!;
      expect(value.income.current, 6000);
      expect(value.income.previous, 2000);
      expect(value.withdrawals.current, 1000);
      expect(value.netCash.current, 5000);
      // May includes the later allocation and subtracts the active June refund.
      expect(value.paidQuota.previous, 4500);
      expect(value.paidQuota.current, 1000);
      expect(value.pendingQuota.previous, 0);
      expect(value.pendingQuota.current, 1000);
      expect(value.coverage.difference, -5000);
      final unknown = compare(
        selection,
        DateTime.utc(2026, 6, 15),
        configured: false,
      )!;
      expect(unknown.expectedQuota.current, isNull);
      expect(unknown.pendingQuota.difference, isNull);
      expect(unknown.coverage.current, isNull);
      expect(
        () => const ReportComparisonRepository().summarize(
          groupId: 'other',
          selection: selection,
          today: DateTime.utc(2026, 6, 15),
          persons: fixtures.people,
          movements: money,
          rules: quotas.rules,
          periods: fixtures.periods,
          allocations: fixtures.allocations,
          quotaRepository: quotaRepository,
        ),
        throwsA(isA<AppFailure>()),
      );
      expect(
        () => const EconomicReportRepository().summarize(
          'a',
          [
            fixtures.income('huge', 'p', 9000000000000000000),
            fixtures.income('huge2', 'p', 9000000000000000000),
          ],
          fixtures.people,
          selection,
        ),
        throwsA(isA<AppFailure>()),
      );
    },
  );
}
