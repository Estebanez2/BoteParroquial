import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';
import '../models/group_member.dart';
import '../models/person.dart';
import 'member_link_service.dart';

class FirestoreMemberLinkService implements MemberLinkService {
  const FirestoreMemberLinkService(this._db);
  final FirebaseFirestore _db;
  static const _conflict = AppFailure(
    FailureCode.invalidData,
    'La vinculación ha cambiado. Actualiza los miembros y personas antes de guardar.',
  );
  @override
  Future<void> change(
    String groupId,
    String actorUid,
    GroupMember target,
    Person? previous,
    Person? next,
  ) async {
    final member = _db.doc(FirestorePaths.member(groupId, target.uid));
    final oldPerson = previous == null
        ? null
        : _db.doc(FirestorePaths.person(groupId, previous.id));
    final newPerson = next == null
        ? null
        : _db.doc(FirestorePaths.person(groupId, next.id));
    final audit = _db.collection(FirestorePaths.auditEvents(groupId)).doc();
    try {
      await _db.runTransaction((tx) async {
        final before = (await tx.get(member)).data();
        final oldData = oldPerson == null
            ? null
            : (await tx.get(oldPerson)).data();
        final newData = newPerson == null
            ? null
            : (await tx.get(newPerson)).data();
        if (before == null ||
            before['updatedAt'] != Timestamp.fromDate(target.updatedAt) ||
            before['personId'] != previous?.id ||
            (previous != null &&
                (oldData?['linkedUid'] != target.uid ||
                    oldData?['updatedAt'] !=
                        Timestamp.fromDate(previous.updatedAt))) ||
            (next != null &&
                (newData == null ||
                    newData['updatedAt'] !=
                        Timestamp.fromDate(next.updatedAt) ||
                    newData['linkedUid'] != null))) {
          throw _conflict;
        }
        final now = FieldValue.serverTimestamp();
        final role = before['role'] == 'admin' && newData?['isActive'] != true
            ? 'member'
            : before['role'];
        tx.update(member, {
          'personId': next?.id,
          'role': role,
          'updatedAt': now,
          'lastAuditEventId': audit.id,
        });
        if (oldPerson != null) {
          tx.update(oldPerson, {
            'linkedUid': null,
            'updatedBy': actorUid,
            'updatedAt': now,
            'lastAuditEventId': audit.id,
          });
        }
        if (newPerson != null) {
          tx.update(newPerson, {
            'linkedUid': target.uid,
            'updatedBy': actorUid,
            'updatedAt': now,
            'lastAuditEventId': audit.id,
          });
        }
        tx.set(audit, {
          'action': 'member.linkChanged',
          'entityType': 'member',
          'entityId': target.uid,
          'actorUid': actorUid,
          'createdAt': now,
          'before': {
            'uid': target.uid,
            'personId': previous?.id,
            'role': before['role'],
          },
          'after': {'uid': target.uid, 'personId': next?.id, 'role': role},
        });
      });
    } on FirebaseException catch (error) {
      throw switch (error.code) {
        'resource-exhausted' => firestoreQuotaFailure,
        'permission-denied' || 'unauthenticated' => const AppFailure(
          FailureCode.permissionDenied,
          'Ya no tienes permiso para cambiar esta vinculación.',
        ),
        'unavailable' || 'deadline-exceeded' => const AppFailure(
          FailureCode.network,
          'Se necesita conexión. Actualiza el vínculo antes de repetir el cambio.',
        ),
        _ => const AppFailure(
          FailureCode.unknown,
          'No se pudo confirmar la vinculación. Actualiza antes de repetirla.',
        ),
      };
    }
  }
}
