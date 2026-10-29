import '../core/errors/app_failure.dart';
import '../models/economic_report.dart';
import '../models/movement.dart';
import '../models/participation_period.dart';
import '../models/person.dart';
import '../models/quota_allocation.dart';
import '../models/quota_report.dart';
import '../models/quota_rule.dart';
import '../models/quota_settlement.dart';
import '../models/year_month.dart';
import '../services/group_quota_service.dart';
import 'quota_settlement_repository.dart';

final class QuotaReportRepository {
  const QuotaReportRepository(this._service);
  final GroupQuotaService _service;
  Stream<List<ParticipationPeriod>> watchPeriods(String groupId) =>
      _service.watchPeriods(groupId);
  Stream<List<QuotaAllocation>> watchAllocations(String groupId) =>
      _service.watchAllocations(groupId);

  /// Combine already projected months without changing payment/refund semantics.
  static QuotaTotals totalsForMonths(Iterable<QuotaMonthReport> months) =>
      _group(months.map((month) => month.summary.totals)).totals;
  static const _invalid = AppFailure(
    FailureCode.invalidData,
    'Las cuotas no forman un conjunto completo de personas y movimientos de este grupo. Actualiza los datos para revisar el informe.',
  );

  QuotaReport summarize({
    required String groupId,
    required YearMonth currentMonth,
    required ReportSelection selection,
    required List<Person> persons,
    required List<Movement> movements,
    required List<QuotaRule> rules,
    required List<ParticipationPeriod> periods,
    required List<QuotaAllocation> allocations,
  }) {
    if (groupId.isEmpty ||
        selection.year < 2000 ||
        selection.year > 2100 ||
        selection.month < 1 ||
        selection.month > 12) {
      throw _invalid;
    }
    final people = <String, Person>{},
        byPersonPeriods = <String, List<ParticipationPeriod>>{},
        byPersonAllocations = <String, List<QuotaAllocation>>{},
        byPersonMoney = <String, List<Movement>>{};
    for (final person in persons) {
      if (person.groupId != groupId ||
          people.containsKey(person.id) ||
          person.id.isEmpty) {
        throw _invalid;
      }
      people[person.id] = person;
    }
    if (rules.any((r) => r.groupId != groupId)) throw _invalid;
    final ids = <String>{};
    for (final movement in movements) {
      if (movement.groupId != groupId || !ids.add(movement.id)) throw _invalid;
      if (movement.input.personId case final personId?) {
        if (!people.containsKey(personId)) throw _invalid;
        byPersonMoney.putIfAbsent(personId, () => []).add(movement);
      }
    }
    for (final period in periods) {
      if (period.groupId != groupId || !people.containsKey(period.personId)) {
        throw _invalid;
      }
      byPersonPeriods.putIfAbsent(period.personId, () => []).add(period);
    }
    for (final allocation in allocations) {
      if (allocation.groupId != groupId ||
          !people.containsKey(allocation.personId)) {
        throw _invalid;
      }
      byPersonAllocations
          .putIfAbsent(allocation.personId, () => [])
          .add(allocation);
    }
    final first = YearMonth(selection.year, selection.startMonth),
        last = YearMonth(
          selection.year,
          selection.startMonth + selection.monthCount - 1,
        );
    final payments = <String, List<MonthQuotaPayment>>{},
        rows = <PersonQuotaReport>[];
    var unallocated = 0, futureCredit = 0;
    for (final person in persons) {
      final settlement = const QuotaSettlementRepository().summarize(
        groupId: groupId,
        personId: person.id,
        currentMonth: currentMonth,
        rules: rules,
        periods: byPersonPeriods[person.id] ?? [],
        movements: byPersonMoney[person.id] ?? [],
        allocations: byPersonAllocations[person.id] ?? [],
        includeFromMonth: first,
        includeUntilMonth: last,
      );
      final own = settlement.months;
      payments[person.id] = own;
      bool inPeriod(MonthQuotaPayment m) =>
          !m.month.isBefore(first) && !m.month.isAfter(last);
      rows.add(
        PersonQuotaReport(
          person: person,
          elapsed: _totals(own.where((m) => inPeriod(m) && !m.isFuture)),
          forecast: _totals(own.where((m) => inPeriod(m) && m.isFuture)),
          accumulated: _totals(own.where((m) => !m.isFuture)),
          unallocatedCreditCents: settlement.unallocatedCreditCents,
          futureCreditCents: settlement.futureCreditCents,
        ),
      );
      unallocated = _add(unallocated, settlement.unallocatedCreditCents);
      futureCredit = _add(futureCredit, settlement.futureCreditCents);
    }
    // Incomplete/owing records first, stable name/ID ordering within each state.
    rows.sort((a, b) {
      int order(QuotaPersonStatus s) => switch (s) {
        QuotaPersonStatus.incomplete => 0,
        QuotaPersonStatus.pending => 1,
        QuotaPersonStatus.partial => 2,
        QuotaPersonStatus.paid => 3,
        QuotaPersonStatus.notApplicable => 4,
      };
      final state = order(a.elapsed.status).compareTo(order(b.elapsed.status));
      if (state != 0) return state;
      final name = a.person.displayName.toLowerCase().compareTo(
        b.person.displayName.toLowerCase(),
      );
      return name != 0 ? name : a.person.id.compareTo(b.person.id);
    });
    return QuotaReport(
      groupId: groupId,
      firstMonth: first,
      lastMonth: last,
      currentMonth: currentMonth,
      elapsed: _group(rows.map((r) => r.elapsed)),
      forecast: _group(rows.map((r) => r.forecast)),
      accumulated: _group(rows.map((r) => r.accumulated)),
      persons: rows,
      unallocatedCreditCents: unallocated,
      futureCreditCents: futureCredit,
      months: [
        for (var n = first.ordinal; n <= last.ordinal; n++)
          QuotaMonthReport(
            month: YearMonth(n ~/ 12, n % 12 + 1),
            isFuture: n > currentMonth.ordinal,
            summary: _group(
              persons.map(
                (person) => _totals(
                  payments[person.id]!.where((m) => m.month.ordinal == n),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static int _add(int a, int b) {
    final result = a + b;
    if (a < 0 || b < 0 || result < a || result < b) throw _invalid;
    return result;
  }

  static QuotaTotals _totals(Iterable<MonthQuotaPayment> rows) {
    var expected = 0,
        paid = 0,
        covered = 0,
        pending = 0,
        overpaid = 0,
        unknown = 0;
    for (final row in rows) {
      paid = _add(paid, row.allocatedCents);
      final due = row.expectation.expectedCents;
      if (due == null) {
        unknown++;
        continue;
      }
      expected = _add(expected, due);
      pending = _add(pending, row.pendingCents!);
      covered = _add(
        covered,
        row.allocatedCents < due ? row.allocatedCents : due,
      );
      if (row.allocatedCents > due) {
        overpaid = _add(overpaid, row.allocatedCents - due);
      }
    }
    return QuotaTotals(
      knownExpectedCents: expected,
      allocatedCents: paid,
      coveredCents: covered,
      knownPendingCents: pending,
      overpaidCents: overpaid,
      unknownMonthsCount: unknown,
    );
  }

  static QuotaGroupSlice _group(Iterable<QuotaTotals> rows) {
    var expected = 0,
        paid = 0,
        covered = 0,
        pending = 0,
        overpaid = 0,
        unknown = 0;
    final counts = <QuotaPersonStatus, int>{};
    for (final row in rows) {
      expected = _add(expected, row.knownExpectedCents);
      paid = _add(paid, row.allocatedCents);
      covered = _add(covered, row.coveredCents);
      pending = _add(pending, row.knownPendingCents);
      overpaid = _add(overpaid, row.overpaidCents);
      unknown += row.unknownMonthsCount;
      counts.update(row.status, (n) => n + 1, ifAbsent: () => 1);
    }
    return QuotaGroupSlice(
      totals: QuotaTotals(
        knownExpectedCents: expected,
        allocatedCents: paid,
        coveredCents: covered,
        knownPendingCents: pending,
        overpaidCents: overpaid,
        unknownMonthsCount: unknown,
      ),
      people: counts,
    );
  }
}
