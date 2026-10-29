import '../models/quota_rule.dart';
import '../models/year_month.dart';

abstract interface class QuotaService {
  Stream<List<QuotaRule>> watchRules(String groupId);
  Stream<List<QuotaRule>> watchVersions(String groupId, String ruleId);
  Future<void> saveRule(
    String groupId,
    String actorUid,
    YearMonth month,
    int cents,
    QuotaRule? original,
  );
}
