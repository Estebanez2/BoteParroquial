import '../core/errors/app_failure.dart';
import '../models/quota_rule.dart';
import '../models/year_month.dart';
import '../services/quota_service.dart';

class QuotaRepository {
  const QuotaRepository(this._service);
  final QuotaService _service;
  Stream<List<QuotaRule>> watchRules(String groupId) =>
      _service.watchRules(groupId);
  Stream<List<QuotaRule>> watchVersions(String groupId, String ruleId) =>
      _service.watchVersions(groupId, ruleId);
  static String? amountError(int? cents) =>
      cents == null || cents < 0 || cents > 99999999999999
      ? 'Introduce una cuota válida, de cero o más.'
      : null;
  static QuotaRule? atMonth(List<QuotaRule> rules, YearMonth month) {
    QuotaRule? result;
    for (final rule in rules) {
      if (!rule.effectiveFrom.isAfter(month) &&
          (result == null ||
              rule.effectiveFrom.isAfter(result.effectiveFrom))) {
        result = rule;
      }
    }
    return result;
  }

  Future<void> saveRule({
    required String groupId,
    required String actorUid,
    required YearMonth month,
    required YearMonth currentMonth,
    required int? cents,
    required List<QuotaRule> rules,
  }) {
    final error = amountError(cents);
    if (error != null) throw AppFailure(FailureCode.invalidData, error);
    if (rules.any((r) => r.groupId != groupId) ||
        (rules.isNotEmpty && !month.isAfter(currentMonth))) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Los cambios solo pueden empezar desde el mes siguiente.',
      );
    }
    QuotaRule? original;
    for (final rule in rules) {
      if (rule.effectiveFrom == month) original = rule;
    }
    return _service.saveRule(groupId, actorUid, month, cents!, original);
  }
}
