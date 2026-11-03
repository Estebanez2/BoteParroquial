import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';
import '../models/initial_quota_assignment.dart';
import '../models/movement.dart';

abstract final class FirestoreInitialQuotaMutation {
  static const conflict = AppFailure(
    FailureCode.invalidData,
    'El ingreso o su cuota han cambiado. Revisa el historial antes de repetir.',
  );
  static String auditId(String movementId, InitialQuotaAssignment assignment) =>
      '${movementId}_quota_${sha256.convert(utf8.encode(jsonEncode(assignment.toMap()))).toString().substring(0, 16)}';
  static Map<String, Object> summary(
    String id,
    String personId,
    InitialQuotaAssignment assignment,
  ) => {
    'movementId': id,
    'personId': personId,
    'month': assignment.month.ordinal,
    'amountCents': assignment.amountCents,
    'revision': 1,
  };
  static bool matches(
    Map<String, dynamic>? audit,
    String actor,
    String id,
    InitialQuotaAssignment assignment,
  ) {
    final after = audit?['after'];
    return audit?['action'] == 'allocation.changed' &&
        audit?['actorUid'] == actor &&
        audit?['entityType'] == 'allocation' &&
        audit?['entityId'] == '${id}_${assignment.month.ordinal}' &&
        audit?['before'] == null &&
        after is Map &&
        after['movementId'] == id &&
        after['month'] == assignment.month.ordinal &&
        after['amountCents'] == assignment.amountCents &&
        after['revision'] == 1;
  }

  static Future<void Function()?> prepare(
    FirebaseFirestore store,
    Transaction tx, {
    required String groupId,
    required String movementId,
    required String actorUid,
    required MovementInput input,
    required InitialQuotaAssignment assignment,
    required bool existing,
  }) async {
    if (input.type != MovementType.income ||
        input.personId == null ||
        input.refund != null ||
        assignment.amountCents <= 0 ||
        assignment.amountCents > input.amountCents) {
      throw conflict;
    }
    final eventId = auditId(movementId, assignment);
    final auditRef = store.doc(FirestorePaths.auditEvent(groupId, eventId));
    final audit = (await tx.get(auditRef)).data();
    if (existing) {
      if (!matches(audit, actorUid, movementId, assignment) ||
          (audit!['after'] as Map)['personId'] != input.personId) {
        throw conflict;
      }
      return null;
    }
    final rowId = '${movementId}_${assignment.month.ordinal}';
    final row = store.doc(FirestorePaths.allocation(groupId, rowId));
    final balance = store.doc(
      FirestorePaths.allocationBalance(groupId, movementId),
    );
    if (audit != null ||
        (await tx.get(row)).exists ||
        (await tx.get(balance)).exists) {
      throw conflict;
    }
    final period = (await tx.get(
      store.doc(
        FirestorePaths.participationPeriod(
          groupId,
          assignment.participationPeriodId,
        ),
      ),
    )).data();
    if (period?['personId'] != input.personId ||
        period?['firstMonth'] is! int ||
        period!['firstMonth'] > assignment.month.ordinal ||
        (period['lastMonthInclusive'] != null &&
            period['lastMonthInclusive'] < assignment.month.ordinal)) {
      throw conflict;
    }
    return () {
      final now = FieldValue.serverTimestamp();
      final after = summary(movementId, input.personId!, assignment);
      tx.set(row, {
        ...after,
        'participationPeriodId': assignment.participationPeriodId,
        'createdBy': actorUid,
        'createdAt': now,
        'updatedBy': actorUid,
        'updatedAt': now,
        'lastAuditEventId': eventId,
      });
      tx.set(balance, {
        'allocatedCents': assignment.amountCents,
        'revision': 1,
        'lastAllocationId': rowId,
        'lastAuditEventId': eventId,
        'updatedAt': now,
        'updatedBy': actorUid,
      });
      tx.set(auditRef, {
        'action': 'allocation.changed',
        'entityType': 'allocation',
        'entityId': rowId,
        'actorUid': actorUid,
        'createdAt': now,
        'before': null,
        'after': after,
      });
    };
  }
}
