import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/models/participation_period.dart';
import 'package:bote_parroquial/models/quota_expectation.dart';
import 'package:bote_parroquial/models/quota_rule.dart';
import 'package:bote_parroquial/models/year_month.dart';
import 'package:bote_parroquial/repositories/quota_expectation_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final month = YearMonth.parse;
QuotaRule rule(String start, int cents, {String group = 'a'}) => QuotaRule(
  id: start,
  groupId: group,
  effectiveFrom: month(start),
  monthlyFeeCents: cents,
);
ParticipationPeriod period(
  String start, {
  String? end,
  String group = 'a',
  String person = 'p',
}) => ParticipationPeriod(
  id: start,
  groupId: group,
  personId: person,
  firstMonth: month(start),
  lastMonthInclusive: end == null ? null : month(end),
);

void main() {
  const repository = QuotaExpectationRepository();
  PersonQuotaExpectation summarize(
    List<QuotaRule> rules,
    List<ParticipationPeriod> periods,
  ) => repository.summarize(
    groupId: 'a',
    personId: 'p',
    firstMonth: month('2026-01'),
    lastMonth: month('2026-12'),
    rules: rules,
    periods: periods,
  );

  test(
    'Mes civil y cuotas temporales respetan bajas, reentradas y céntimos sin mutar historia',
    () {
      expect(month('2026-12').addMonths(1), month('2027-01'));
      expect(month('2026-01').addMonths(-1), month('2025-12'));
      expect(YearMonth.fromDate(DateTime.utc(2024, 2, 29)), month('2024-02'));
      expect(() => month('2026-13'), throwsFormatException);
      expect(() => YearMonth(2026, 0), throwsArgumentError);
      final rules = [rule('2026-07', 2500), rule('2026-01', 2050)];
      final periods = [period('2026-09'), period('2026-01', end: '2026-05')];
      final result = summarize(rules, periods);
      expect(result.knownExpectedCents, 5 * 2050 + 4 * 2500);
      expect(result.isComplete, true);
      expect(result.months[4].expectedCents, 2050);
      expect(result.months[5].state, QuotaExpectationState.notApplicable);
      expect(result.months[7].expectedCents, 0);
      expect(result.months[8].expectedCents, 2500);
      expect(result.months[8].ruleId, '2026-07');
      expect(rules.first.effectiveFrom, month('2026-07'));
      expect(periods.first.firstMonth, month('2026-09'));
      expect(() => result.months.clear(), throwsUnsupportedError);
      final shared = summarize(
        [rule('2026-01', 2000)],
        [
          ParticipationPeriod(
            id: 'new-open',
            groupId: 'a',
            personId: 'p',
            firstMonth: month('2026-10'),
          ),
          ParticipationPeriod(
            id: 'closed-same-month',
            groupId: 'a',
            personId: 'p',
            firstMonth: month('2026-10'),
            lastMonthInclusive: month('2026-10'),
          ),
        ],
      );
      expect(shared.knownExpectedCents, 6000);
      expect(shared.months[9].expectedCents, 2000);
    },
  );
  test(
    'Historial incompleto no equivale a deuda cero; rechaza mezclas de grupos y periodos ambiguos',
    () {
      final incomplete = summarize(
        [rule('2026-03', 2000)],
        [period('2026-01')],
      );
      expect(incomplete.isComplete, false);
      expect(incomplete.months.first.expectedCents, isNull);
      expect(incomplete.months.first.state, QuotaExpectationState.missingRule);
      expect(incomplete.knownExpectedCents, 20000);
      final withoutPeriods = summarize([rule('2026-01', 2000)], []);
      expect(
        withoutPeriods.months.every(
          (m) => m.state == QuotaExpectationState.participationNotConfigured,
        ),
        true,
      );
      expect(withoutPeriods.isComplete, false);
      expect(withoutPeriods.months.first.expectedCents, isNull);
      for (final rules in [
        [rule('2026-01', -1)],
        [rule('2026-01', 2000, group: 'other')],
        [rule('2026-01', 2000), rule('2026-01', 2500)],
      ]) {
        expect(
          () => summarize(rules, [period('2026-01')]),
          throwsA(isA<AppFailure>()),
        );
      }
      for (final periods in [
        [period('2026-02', end: '2026-01')],
        [period('2026-01', end: '2026-03'), period('2026-02')],
        [period('2026-01'), period('2026-09')],
        [period('2026-01', group: 'other')],
        [period('2026-01', person: 'other')],
      ]) {
        expect(
          () => summarize([rule('2026-01', 2000)], periods),
          throwsA(isA<AppFailure>()),
        );
      }
    },
  );
}
