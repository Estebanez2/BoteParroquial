import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';
import '../models/audit_history.dart';

GroupAuditEvent decodeAuditEvent(
  String groupId,
  String documentId,
  String documentPath,
  Map<String, Object?> data,
) {
  const invalid = AppFailure(
    FailureCode.invalidData,
    'Un evento administrativo no tiene un formato válido.',
  );
  final timestamp = data['createdAt'];
  if (documentPath != FirestorePaths.auditEvent(groupId, documentId) ||
      data['action'] is! String ||
      data['actorUid'] is! String ||
      data['entityId'] is! String ||
      timestamp is! Timestamp ||
      (data.containsKey('entityType') && data['entityType'] is! String)) {
    throw invalid;
  }
  Map<String, Object?> flat(Object? raw) {
    if (raw is! Map ||
        raw.keys.any((key) => key is! String) ||
        raw.values.any(
          (value) =>
              value != null &&
              value is! String &&
              value is! bool &&
              value is! int,
        )) {
      throw invalid;
    }
    return Map<String, Object?>.unmodifiable(raw.cast<String, Object?>());
  }

  return GroupAuditEvent(
    position: AuditCursor(
      groupId: groupId,
      eventId: documentId,
      seconds: timestamp.seconds,
      nanoseconds: timestamp.nanoseconds,
    ),
    action: data['action'] as String,
    actorUid: data['actorUid'] as String,
    entityId: data['entityId'] as String,
    entityType: data['entityType'] as String? ?? 'group',
    before: data['before'] == null ? null : flat(data['before']),
    after: flat(data['after']),
  );
}
