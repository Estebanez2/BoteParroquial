// Runs the actual pure domain projections against the seed, without SDK/network.
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
import 'package:bote_parroquial/repositories/quota_report_repository.dart';
import 'package:bote_parroquial/services/group_quota_service.dart';

class _UnusedSource implements GroupQuotaService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('No network');
}

void main() {
  final data =
      jsonDecode(File('.dart_tool/demo-dataset.json').readAsStringSync())
          as Map;
  final documents = data['documents'] as List;
  final results = <Map<String, Object?>>[];
  YearMonth month(int n) => YearMonth(n ~/ 12, n % 12 + 1);
  for (final group in data['groups'] as List) {
    final id = group['id'] as String;
    List<Map> rows(String collection) => documents
        .where(
          (d) =>
              (d['path'] as String).startsWith('groups/$id/$collection/') &&
              (d['path'] as String).split('/').length == 4,
        )
        .map(
          (d) => <Object?, Object?>{
            'id': (d['path'] as String).split('/').last,
            ...d['data'] as Map,
          },
        )
        .toList();
    final people = rows('persons')
        .where((p) => p['trashedAt'] == null)
        .map(
          (p) => Person(
            id: p['id'],
            groupId: id,
            displayName: p['displayName'],
            notes: p['notes'],
            isActive: p['isActive'],
            linkedUid: p['linkedUid'],
            lastParticipationPeriodId: p['lastParticipationPeriodId'],
            createdBy: p['createdBy'],
            updatedBy: p['updatedBy'],
            createdAt: DateTime.parse(p['createdAt']),
            updatedAt: DateTime.parse(p['updatedAt']),
          ),
        )
        .toList();
    final movements = rows('movements')
        .map(
          (m) => Movement(
            id: m['id'],
            groupId: id,
            status: MovementStatus.values.byName(m['status']),
            createdBy: m['createdBy'],
            createdAt: DateTime.parse(m['createdAt']),
            updatedAt: DateTime.parse(m['updatedAt']),
            correctionOfMovementId: m['correctionOfMovementId'],
            correctedByMovementId: m['correctedByMovementId'],
            input: MovementInput(
              type: MovementType.values.byName(m['type']),
              amountCents: m['amountCents'],
              personId: m['personId'],
              occurredAt: DateTime.parse(m['occurredAt']),
              description: m['description'],
              refund: RefundPlan.fromMap(m['refund']),
            ),
          ),
        )
        .toList();
    final report = QuotaReportRepository(_UnusedSource()).summarize(
      groupId: id,
      currentMonth: YearMonth(2026, 10),
      selection: const ReportSelection(
        year: 2026,
        month: 10,
        period: ReportPeriod.year,
      ),
      persons: people,
      movements: movements,
      rules: rows('quotaRules')
          .map(
            (q) => QuotaRule(
              id: q['id'],
              groupId: id,
              effectiveFrom: month(q['effectiveFromMonth']),
              monthlyFeeCents: q['monthlyFeeCents'],
              revision: q['revision'],
            ),
          )
          .toList(),
      periods: rows('participationPeriods')
          .map(
            (p) => ParticipationPeriod(
              id: p['id'],
              groupId: id,
              personId: p['personId'],
              firstMonth: month(p['firstMonth']),
              lastMonthInclusive: p['lastMonthInclusive'] == null
                  ? null
                  : month(p['lastMonthInclusive']),
            ),
          )
          .toList(),
      allocations: rows('allocations')
          .map(
            (a) => QuotaAllocation(
              id: a['id'],
              groupId: id,
              movementId: a['movementId'],
              personId: a['personId'],
              month: month(a['month']),
              amountCents: a['amountCents'],
              revision: a['revision'],
              participationPeriodId: a['participationPeriodId'],
            ),
          )
          .toList(),
    );
    if (!report.accumulated.totals.isComplete ||
        report.accumulated.totals.pendingCents == null) {
      throw StateError('Incomplete DEMO quotas');
    }
    final cash = movements.fold<int>(0, (n, m) => n + m.contributionCents);
    if (cash != group['balanceCents']) throw StateError('DEMO cash mismatch');
    results.add({
      'groupId': id,
      'balanceCents': cash,
      'expectedToOctoberCents': report.accumulated.totals.expectedCents,
      'paidToOctoberCents': report.accumulated.totals.allocatedCents,
      'pendingToOctoberCents': report.accumulated.totals.pendingCents,
      'coverageBasisPoints': report.accumulated.totals.coverageBasisPoints,
      'overpaidCents': report.accumulated.totals.overpaidCents,
      'freeCreditCents': report.unallocatedCreditCents,
      'futureAssignedCents': report.futureCreditCents,
      'october': {
        'expectedCents': report.months[9].summary.totals.expectedCents,
        'paidCents': report.months[9].summary.totals.allocatedCents,
        'pendingCents': report.months[9].summary.totals.pendingCents,
      },
    });
  }
  File(
    '.dart_tool/demo-domain-validation.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(results));
  stdout.writeln(
    jsonEncode({
      'groups': results,
      'validatedWith': 'actual QuotaReportRepository and RefundPlan',
      'remoteWrites': 0,
    }),
  );
}
