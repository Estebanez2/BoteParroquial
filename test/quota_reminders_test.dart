import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/models/economic_report.dart';
import 'package:bote_parroquial/models/quota_reminder.dart';
import 'package:bote_parroquial/models/quota_report.dart';
import 'package:bote_parroquial/models/quota_rule.dart';
import 'package:bote_parroquial/models/year_month.dart';
import 'package:bote_parroquial/repositories/quota_reminder_repository.dart';
import 'package:bote_parroquial/repositories/quota_report_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'quota_allocations_test.dart' as quota;
import 'quota_reports_test.dart' as fixture;

void main() {
  const reminders = QuotaReminderRepository();

  test('Fechas civiles: febrero bisiesto, meses cortos y diciembre', () {
    for (final entry in <YearMonth, List<int>>{
      YearMonth(2028, 2): [22, 28],
      YearMonth(2026, 2): [21, 27],
      YearMonth(2026, 6): [23, 29],
      YearMonth(2026, 12): [24, 30],
    }.entries) {
      final dates = reminders.datesFor(entry.key);
      expect(dates.values.map((d) => d.day), entry.value);
      expect(dates.values.every((d) => d.isUtc), isTrue);
      expect(dates.values.every((d) => d.month == entry.key.month), isTrue);
    }
  });

  final service = fixture.MemoryGroupQuotas();
  final reports = QuotaReportRepository(service);
  tearDownAll(() => service.changes.close());
  QuotaReport report({
    List<QuotaRule>? rules,
    bool active = true,
    int junePaid = 1000,
  }) => reports.summarize(
    groupId: 'a',
    currentMonth: quota.june,
    selection: const ReportSelection(year: 2026, month: 6),
    persons: [fixture.person('p', active: active)],
    rules: rules ?? quota.rules,
    periods: quota.periods,
    movements: [fixture.money.first, fixture.money.last],
    allocations: [
      fixture.allocations.first,
      fixture.allocation('one', 'p', quota.june, junePaid),
    ],
  );

  test('Solo deuda mensual conocida: reparto neto, crédito e inactividad', () {
    QuotaReminderPlan prepare(QuotaReport data) => reminders.prepare(
      groupId: 'a',
      groupToday: DateTime.utc(2026, 6, 23),
      monthlyReport: data,
    )!;
    final plan = prepare(report());
    expect(plan.stage, QuotaReminderStage.sevenDaysBeforeEnd);
    final item = plan.candidates.single;
    expect(item.personId, 'p');
    expect(item.expectedCents, 2000);
    expect(item.paidCents, 1000);
    // The income's remaining credit and May's overpayment do not pay June.
    expect(item.pendingCents, 1000);
    expect(prepare(report(junePaid: 2000)).candidates, isEmpty);
    expect(prepare(report(active: false)).candidates, isEmpty);
    final unknown = prepare(report(rules: []));
    expect(unknown.candidates, isEmpty);
    expect(unknown.unconfiguredPersonIds, ['p']);
  });

  test('No plan fuera de fecha; rechaza otro grupo e informe antiguo', () {
    final data = report();
    expect(
      reminders.prepare(
        groupId: 'a',
        groupToday: DateTime.utc(2026, 6, 24),
        monthlyReport: data,
      ),
      isNull,
    );
    expect(
      reminders
          .prepare(
            groupId: 'a',
            groupToday: DateTime.utc(2026, 6, 29),
            monthlyReport: data,
          )
          ?.stage,
      QuotaReminderStage.oneDayBeforeEnd,
    );
    for (final arguments in [
      ('b', DateTime.utc(2026, 6, 23)),
      ('a', DateTime.utc(2026, 7, 24)),
    ]) {
      expect(
        () => reminders.prepare(
          groupId: arguments.$1,
          groupToday: arguments.$2,
          monthlyReport: data,
        ),
        throwsA(isA<AppFailure>()),
      );
    }
  });
}
