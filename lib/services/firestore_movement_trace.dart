import 'package:cloud_firestore/cloud_firestore.dart';

/// Transaction witnesses for audit and race-safe trash eligibility.
class FirestoreMovementTrace {
  static Future<void Function()> prepareHistory(
    FirebaseFirestore db,
    Transaction tx,
    String groupId,
    String movementId,
    String? personId,
    String actorUid,
  ) async {
    if (personId == null) return () {};
    final reference = db.doc('groups/$groupId/persons/$personId');
    final previous = (await tx.get(reference)).data();
    return () {
      if (previous != null && previous['firstMovementId'] == null) {
        tx.update(reference, {'firstMovementId': movementId});
      }
    };
  }

  static Map<String, Object?> summary(Map<String, dynamic> value) => {
    for (final key in [
      'type',
      'amountCents',
      'personId',
      'occurredAt',
      'description',
      'status',
      'correctionOfMovementId',
      'correctedByMovementId',
      'cancellationReason',
      'correctionReason',
    ])
      key: value[key],
  };
  static void write(
    FirebaseFirestore db,
    Transaction tx,
    String groupId,
    String id,
    String actorUid,
    String operation,
    Map<String, dynamic>? before,
    Map<String, dynamic> after,
  ) {
    tx.set(db.doc('groups/$groupId/auditEvents/movement-$operation-$id'), {
      'action': 'movement.$operation',
      'entityType': 'movement',
      'entityId': id,
      'actorUid': actorUid,
      'createdAt': FieldValue.serverTimestamp(),
      'before': before == null ? null : summary(before),
      'after': summary(after),
    });
  }
}
