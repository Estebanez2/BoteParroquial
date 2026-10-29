import 'dart:convert';
import 'dart:io';

import 'package:bote_parroquial/models/economic_report.dart';
import 'package:bote_parroquial/models/movement.dart';
import 'package:bote_parroquial/models/participation_period.dart';
import 'package:bote_parroquial/models/person.dart';
import 'package:bote_parroquial/models/quota_allocation.dart';
import 'package:bote_parroquial/models/quota_rule.dart';
import 'package:bote_parroquial/models/refund_plan.dart';
import 'package:bote_parroquial/models/year_month.dart';
import 'package:bote_parroquial/repositories/quota_reminder_repository.dart';
import 'package:bote_parroquial/repositories/quota_report_repository.dart';
import 'package:bote_parroquial/services/group_quota_service.dart';
import 'package:flutter_test/flutter_test.dart';

// This projection test must never subscribe to Firebase or a fake data source.
class _UnusedQuotaService implements GroupQuotaService {
  @override
  Stream<List<ParticipationPeriod>> watchPeriods(String groupId) =>
      throw UnimplementedError();
  @override
  Stream<List<QuotaAllocation>> watchAllocations(String groupId) =>
      throw UnimplementedError();
}

YearMonth _month(int ordinal) => YearMonth(ordinal ~/ 12, ordinal % 12 + 1);

void main() {
  test(
    'Shared server fixtures match real Dart monthly reports and candidates',
    () {
      final data =
          jsonDecode(
                File(
                  'test/fixtures/quota_reminder_parity.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final month = _month(data['month'] as int);
      final date = DateTime.utc(month.year, month.month, 1);
      final reports = QuotaReportRepository(_UnusedQuotaService());
      for (final raw in data['cases'] as List) {
        final row = raw as Map<String, Object?>;
        Movement money(
          String id,
          int amount,
          MovementType type,
          String status, [
          RefundPlan? refund,
        ]) => Movement(
          id: id,
          groupId: 'qa',
          status: MovementStatus.values.byName(status),
          createdBy: 'DEMO',
          createdAt: date,
          updatedAt: date,
          input: MovementInput(
            type: type,
            amountCents: amount,
            occurredAt: date,
            description: 'DEMO parity',
            personId: 'p',
            refund: refund,
          ),
        );
        final refund = RefundPlan.fromMap(row['refund']);
        final movements = [
          money(
            'income',
            5000,
            MovementType.income,
            row['incomeStatus'] as String? ?? 'active',
          ),
          if (refund != null)
            money(
              'refund',
              refund.amountCents,
              MovementType.withdrawal,
              row['refundStatus'] as String? ?? 'active',
              refund,
            ),
          if (row['ordinaryWithdrawal'] case final int amount)
            money('withdrawal', amount, MovementType.withdrawal, 'active'),
        ];
        final stages = row['periods'] as List;
        final report = reports.summarize(
          groupId: 'qa',
          currentMonth: month,
          selection: ReportSelection(year: month.year, month: month.month),
          persons: [
            Person(
              id: 'p',
              groupId: 'qa',
              displayName: 'DEMO',
              isActive: true,
              createdBy: 'DEMO',
              updatedBy: 'DEMO',
              createdAt: date,
              updatedAt: date,
            ),
          ],
          movements: movements,
          rules: [
            if (row['fee'] case final int fee)
              QuotaRule(
                id: '24316',
                groupId: 'qa',
                effectiveFrom: _month(24316),
                monthlyFeeCents: fee,
              ),
          ],
          periods: [
            for (var i = 0; i < stages.length; i++)
              ParticipationPeriod(
                id: 'stage$i',
                groupId: 'qa',
                personId: 'p',
                firstMonth: _month((stages[i] as List)[0] as int),
                lastMonthInclusive: (stages[i] as List)[1] == null
                    ? null
                    : _month((stages[i] as List)[1] as int),
              ),
          ],
          allocations: [
            for (final entry
                in (row['allocations'] as Map<String, Object?>).entries)
              QuotaAllocation(
                id: 'income_${entry.key}',
                groupId: 'qa',
                movementId: 'income',
                personId: 'p',
                month: _month(int.parse(entry.key)),
                amountCents: entry.value as int,
                revision: 1,
                participationPeriodId: 'stage0',
              ),
          ],
        );
        final totals = report.persons.single.elapsed;
        final expected = row['expected'] as List;
        expect(
          [
            totals.isComplete ? totals.knownExpectedCents : null,
            totals.allocatedCents,
            totals.isComplete ? totals.knownPendingCents : null,
          ],
          expected,
          reason: row['id'] as String,
        );
        final plan = const QuotaReminderRepository().prepare(
          groupId: 'qa',
          groupToday: DateTime.utc(2026, 6, 23),
          monthlyReport: report,
        );
        expect(
          plan!.candidates.isNotEmpty,
          expected[2] != null && (expected[2] as int) > 0,
          reason: row['id'] as String,
        );
      }
    },
  );
}
