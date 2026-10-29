import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/models/economic_report.dart';
import 'package:bote_parroquial/models/movement.dart';
import 'package:bote_parroquial/models/participation_period.dart';
import 'package:bote_parroquial/models/person.dart';
import 'package:bote_parroquial/models/quota_allocation.dart';
import 'package:bote_parroquial/models/quota_report.dart';
import 'package:bote_parroquial/models/quota_rule.dart';
import 'package:bote_parroquial/models/refund_plan.dart';
import 'package:bote_parroquial/models/year_month.dart';
import 'package:bote_parroquial/repositories/economic_report_repository.dart';
import 'package:bote_parroquial/repositories/quota_report_repository.dart';
import 'package:bote_parroquial/services/group_quota_service.dart';
import 'quota_allocations_test.dart' as quota;

Person person(String id, {bool active = true}) => Person(
  id: id,
  groupId: 'a',
  displayName: id == 'p' ? 'Ana' : 'Beatriz',
  isActive: active,
  createdBy: 'alice',
  updatedBy: 'alice',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
Movement income(
  String id,
  String personId,
  int cents, {
  MovementStatus status = MovementStatus.active,
  DateTime? date,
}) => Movement(
  id: id,
  groupId: 'a',
  status: status,
  createdBy: 'alice',
  createdAt: DateTime.utc(2026, 6, 2),
  updatedAt: DateTime.utc(2026, 6, 2),
  input: MovementInput(
    type: MovementType.income,
    amountCents: cents,
    personId: personId,
    occurredAt: date ?? DateTime.utc(2026, 6, 1),
    description: 'DEMO',
  ),
);
Movement refund({MovementStatus status = MovementStatus.active}) {
  final plan = RefundPlan(
    incomeId: 'one',
    unallocatedCents: 500,
    parts: [RefundPart(month: quota.may, amountCents: 500)],
  );
  return Movement(
    id: 'refund',
    groupId: 'a',
    status: status,
    createdBy: 'alice',
    createdAt: DateTime.utc(2026, 6, 2),
    updatedAt: DateTime.utc(2026, 6, 2),
    input: MovementInput(
      type: MovementType.withdrawal,
      amountCents: 1000,
      personId: 'p',
      occurredAt: DateTime.utc(2026, 6, 2),
      description: 'DEMO',
      refund: plan,
    ),
  );
}

QuotaAllocation allocation(
  String source,
  String personId,
  YearMonth month,
  int cents,
) => QuotaAllocation(
  id: '${source}_${month.ordinal}',
  groupId: 'a',
  movementId: source,
  personId: personId,
  month: month,
  amountCents: cents,
  revision: 1,
  participationPeriodId: personId == 'p' ? 'stage' : 'q-stage',
);
final people = [person('p'), person('q', active: false)];
final periods = [
  ...quota.periods,
  ParticipationPeriod(
    id: 'q-stage',
    groupId: 'a',
    personId: 'q',
    firstMonth: quota.may,
    lastMonthInclusive: quota.may,
  ),
];
final money = [
  income('one', 'p', 6000),
  income('two', 'q', 2000, date: DateTime.utc(2026, 5, 10)),
  refund(),
];
final allocations = [
  allocation('one', 'p', quota.may, 3000),
  allocation('one', 'p', quota.june, 1000),
  allocation('one', 'p', quota.july, 1000),
  allocation('two', 'q', quota.may, 2000),
];

class MemoryGroupQuotas implements GroupQuotaService {
  List<ParticipationPeriod> periods = [];
  List<QuotaAllocation> allocations = [];
  final changes = StreamController<void>.broadcast();
  int periodReads = 0, allocationReads = 0, activeReads = 0;
  @override
  Stream<List<ParticipationPeriod>> watchPeriods(String groupId) async* {
    periodReads++;
    activeReads++;
    try {
      yield List.of(periods.where((p) => p.groupId == groupId));
      yield* changes.stream.map(
        (_) => List.of(periods.where((p) => p.groupId == groupId)),
      );
    } finally {
      activeReads--;
    }
  }

  @override
  Stream<List<QuotaAllocation>> watchAllocations(String groupId) async* {
    allocationReads++;
    activeReads++;
    try {
      yield List.of(allocations.where((a) => a.groupId == groupId));
      yield* changes.stream.map(
        (_) => List.of(allocations.where((a) => a.groupId == groupId)),
      );
    } finally {
      activeReads--;
    }
  }
}

void main() {
  late MemoryGroupQuotas service;
  late QuotaReportRepository repo;
  setUp(() {
    service = MemoryGroupQuotas();
    repo = QuotaReportRepository(service);
  });
  tearDown(() => service.changes.close());
  QuotaReport report(
    ReportSelection selection, {
    List<Person>? persons,
    List<Movement>? movements,
    List<ParticipationPeriod>? stages,
    List<QuotaAllocation>? rows,
    List<QuotaRule>? rules,
    YearMonth? now,
  }) => repo.summarize(
    groupId: 'a',
    currentMonth: now ?? quota.june,
    selection: selection,
    persons: persons ?? people,
    movements: movements ?? money,
    periods: stages ?? periods,
    allocations: rows ?? allocations,
    rules: rules ?? quota.rules,
  );
  test(
    'Mes/trimestre/año separan previsión y deuda; sobrepago no compensa y personas inactivas conservan historia',
    () {
      final annual = report(
        const ReportSelection(year: 2026, month: 6, period: ReportPeriod.year),
      );
      expect(annual.elapsed.totals.knownExpectedCents, 6000);
      expect(annual.elapsed.totals.allocatedCents, 5500);
      expect(annual.elapsed.totals.pendingCents, 1000);
      expect(annual.elapsed.totals.coverageBasisPoints, 8333);
      expect(annual.elapsed.totals.overpaidCents, 500);
      expect(annual.forecast.totals.knownExpectedCents, 12000);
      expect(annual.forecast.totals.pendingCents, 11000);
      expect(annual.futureCreditCents, 1000);
      expect(annual.unallocatedCreditCents, 500);
      expect(annual.elapsed.count(QuotaPersonStatus.paid), 1);
      expect(annual.elapsed.count(QuotaPersonStatus.partial), 1);
      expect(annual.persons.first.person.id, 'p');
      expect(annual.persons.last.person.isActive, false);
      final quarter = report(
        const ReportSelection(
          year: 2026,
          month: 5,
          period: ReportPeriod.quarter,
        ),
      );
      expect(quarter.firstMonth, YearMonth(2026, 4));
      expect(quarter.lastMonth, quota.june);
      expect(quarter.months.length, 3);
      expect(quarter.elapsed.totals.pendingCents, 1000);
      expect(quarter.hasForecast, false);
      final may = report(const ReportSelection(year: 2026, month: 5));
      expect(may.elapsed.totals.pendingCents, 0);
      expect(may.elapsed.totals.allocatedCents, 4500);
      expect(may.elapsed.totals.coverageBasisPoints, 10000);
      final cash = const EconomicReportRepository().summarize(
        'a',
        money,
        people,
        const ReportSelection(year: 2026, month: 5),
      );
      expect(
        cash.incomeCents,
        2000,
      ); // A later payment assigned to May is not May cash.
      final future = report(const ReportSelection(year: 2026, month: 7));
      expect(future.elapsed.totals.pendingCents, 0);
      expect(future.forecast.totals.pendingCents, 1000);
    },
  );
  test(
    'Falta de configuración no se convierte en deuda cero y una cuota cero no inventa un 100 %',
    () {
      final incomplete = report(
        const ReportSelection(year: 2026, month: 6),
        persons: [...people, person('r')],
      );
      expect(incomplete.elapsed.totals.pendingCents, isNull);
      expect(incomplete.elapsed.totals.coverageBasisPoints, isNull);
      expect(incomplete.elapsed.count(QuotaPersonStatus.incomplete), 1);
      final suspended = report(
        const ReportSelection(year: 2026, month: 7),
        now: quota.july,
        rules: [
          ...quota.rules,
          QuotaRule(
            id: 'pause',
            groupId: 'a',
            effectiveFrom: quota.july,
            monthlyFeeCents: 0,
          ),
        ],
      );
      expect(suspended.elapsed.totals.pendingCents, 0);
      expect(suspended.elapsed.totals.coverageBasisPoints, isNull);
      expect(suspended.elapsed.count(QuotaPersonStatus.paid), 0);
      expect(suspended.elapsed.count(QuotaPersonStatus.notApplicable), 2);
      expect(suspended.accumulated.totals.pendingCents, 1000);
      final old = report(
        const ReportSelection(year: 2020, month: 1, period: ReportPeriod.year),
      );
      expect(old.months.length, 12);
      expect(old.elapsed.totals.expectedCents, 0);
      expect(old.elapsed.totals.pendingCents, 0);
      expect(old.elapsed.totals.coverageBasisPoints, isNull);
    },
  );
  test(
    'Pagos/devoluciones activos actualizan el informe, el crédito no paga meses y se rechazan cruces de grupo',
    () {
      final restored = report(
        const ReportSelection(year: 2026, month: 6),
        movements: [
          money[0],
          money[1],
          refund(status: MovementStatus.cancelled),
        ],
      );
      expect(restored.unallocatedCreditCents, 1000);
      final replacement = report(
        const ReportSelection(year: 2026, month: 6),
        movements: [
          income('one', 'p', 6000, status: MovementStatus.corrected),
          money[1],
          refund(status: MovementStatus.cancelled),
          income('new', 'p', 6000),
        ],
      );
      expect(replacement.elapsed.totals.pendingCents, 2000);
      expect(replacement.unallocatedCreditCents, 6000);
      final noAssignments = report(
        const ReportSelection(year: 2026, month: 6),
        rows: [],
        movements: money.take(2).toList(),
      );
      expect(noAssignments.elapsed.totals.pendingCents, 2000);
      expect(noAssignments.unallocatedCreditCents, 8000);
      expect(
        () => repo.summarize(
          groupId: 'b',
          currentMonth: quota.june,
          selection: const ReportSelection(year: 2026, month: 6),
          persons: people,
          movements: money,
          rules: quota.rules,
          periods: periods,
          allocations: allocations,
        ),
        throwsA(isA<AppFailure>()),
      );
      expect(
        () => report(
          const ReportSelection(year: 2026, month: 6),
          persons: [people.first],
        ),
        throwsA(isA<AppFailure>()),
      );
      const large = QuotaTotals(
        knownExpectedCents: 1200000000000000,
        allocatedCents: 600000000000000,
        coveredCents: 600000000000000,
        knownPendingCents: 600000000000000,
        overpaidCents: 0,
        unknownMonthsCount: 0,
      );
      expect(
        large.coverageBasisPoints,
        5000,
      ); // No intermediate int64 multiplication overflow.
    },
  );
}
