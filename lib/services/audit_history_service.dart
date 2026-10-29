import '../models/audit_history.dart';

abstract interface class AuditHistoryService {
  Stream<AuditPage> watchHead(String groupId);
  Future<AuditPage> fetchOlder(String groupId, AuditCursor cursor);
}
