import '../core/errors/app_failure.dart';
import '../models/participation_period.dart';
import '../models/quota_expectation.dart';
import '../models/quota_rule.dart';
import '../models/year_month.dart';

/// Pure projection of explicitly supplied history. Does not infer payments/debt.
class QuotaExpectationRepository {
  const QuotaExpectationRepository();
  static const _invalid = AppFailure(
    FailureCode.invalidData,
    'Las reglas de cuota o los periodos no forman un historial válido para esta persona y grupo.',
  );

  PersonQuotaExpectation summarize({
    required String groupId,
    required String personId,
    required YearMonth firstMonth,
    required YearMonth lastMonth,
    required List<QuotaRule> rules,
    required List<ParticipationPeriod> periods,
  }) {
    if (groupId.isEmpty || personId.isEmpty || lastMonth.isBefore(firstMonth)) {
      throw _invalid;
    }
    final orderedRules = List<QuotaRule>.of(rules)
      ..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
    final ruleIds = <String>{};
    for (var i = 0; i < orderedRules.length; i++) {
      final rule = orderedRules[i];
      if (rule.id.isEmpty ||
          !ruleIds.add(rule.id) ||
          rule.groupId != groupId ||
          rule.monthlyFeeCents < 0 ||
          rule.monthlyFeeCents > 99999999999999 ||
          (i > 0 && orderedRules[i - 1].effectiveFrom == rule.effectiveFrom)) {
        throw _invalid;
      }
    }
    final orderedPeriods = List<ParticipationPeriod>.of(periods)..sort();
    final periodIds = <String>{};
    for (var i = 0; i < orderedPeriods.length; i++) {
      final period = orderedPeriods[i];
      if (period.id.isEmpty ||
          !periodIds.add(period.id) ||
          period.groupId != groupId ||
          period.personId != personId ||
          (period.lastMonthInclusive?.isBefore(period.firstMonth) ?? false)) {
        throw _invalid;
      }
      if (i > 0) {
        final previousEnd = orderedPeriods[i - 1].lastMonthInclusive;
        if (previousEnd == null || period.firstMonth.isBefore(previousEnd)) {
          throw _invalid;
        }
      }
    }
    final result = <MonthQuotaExpectation>[];
    var ruleIndex = -1, periodIndex = 0;
    for (
      var ordinal = firstMonth.ordinal;
      ordinal <= lastMonth.ordinal;
      ordinal++
    ) {
      final month = YearMonth(ordinal ~/ 12, ordinal % 12 + 1);
      while (ruleIndex + 1 < orderedRules.length &&
          !orderedRules[ruleIndex + 1].effectiveFrom.isAfter(month)) {
        ruleIndex++;
      }
      while (periodIndex < orderedPeriods.length &&
          orderedPeriods[periodIndex].lastMonthInclusive != null &&
          orderedPeriods[periodIndex].lastMonthInclusive!.isBefore(month)) {
        periodIndex++;
      }
      final applies =
          periodIndex < orderedPeriods.length &&
          orderedPeriods[periodIndex].includes(month);
      final rule = ruleIndex < 0 ? null : orderedRules[ruleIndex];
      result.add(
        MonthQuotaExpectation(
          month: month,
          state: orderedPeriods.isEmpty
              ? QuotaExpectationState.participationNotConfigured
              : !applies
              ? QuotaExpectationState.notApplicable
              : rule == null
              ? QuotaExpectationState.missingRule
              : QuotaExpectationState.priced,
          expectedCents: orderedPeriods.isEmpty
              ? null
              : !applies
              ? 0
              : rule?.monthlyFeeCents,
          ruleId: applies ? rule?.id : null,
        ),
      );
    }
    return PersonQuotaExpectation(months: result);
  }
}
