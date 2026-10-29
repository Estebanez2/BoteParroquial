import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import 'member_role_service.dart';

class FirestoreMemberRoleService implements MemberRoleService {
  const FirestoreMemberRoleService(this._db);
  final FirebaseFirestore _db;
  static const _conflict = AppFailure(
    FailureCode.invalidData,
    'El grupo, el rol o la vinculación han cambiado. Actualiza antes de continuar.',
  );
  void _checkMember(Map<String, dynamic>? data, GroupMember member) {
    if (data == null ||
        data['uid'] != member.uid ||
        data['updatedAt'] != Timestamp.fromDate(member.updatedAt) ||
        data['role'] != member.role.name ||
        data['status'] != 'active' ||
        data['personId'] != member.personId) {
      throw _conflict;
    }
  }

  Future<void> _checkPerson(
    Transaction tx,
    String groupId,
    GroupMember member,
  ) async {
    final id = member.personId;
    if (id == null) throw _conflict;
    final data = (await tx.get(
      _db.doc(FirestorePaths.person(groupId, id)),
    )).data();
    if (data?['isActive'] != true || data?['linkedUid'] != member.uid) {
      throw _conflict;
    }
  }

  static Map<String, Object?> _summary(GroupMember member, GroupRole role) => {
    'uid': member.uid,
    'personId': member.personId,
    'role': role.name,
  };
  static AppFailure _failure(FirebaseException error) => switch (error.code) {
    'permission-denied' || 'unauthenticated' => const AppFailure(
      FailureCode.permissionDenied,
      'No se pudo autorizar el cambio. Actualiza los miembros; para transferir, verifica de nuevo Google.',
    ),
    'unavailable' || 'deadline-exceeded' => const AppFailure(
      FailureCode.network,
      'Se necesita conexión. Consulta los miembros antes de repetir el cambio.',
    ),
    _ => const AppFailure(
      FailureCode.unknown,
      'No se pudo confirmar el cambio. Revisa los miembros antes de repetirlo.',
    ),
  };
  @override
  Future<void> changeRole(
    String groupId,
    String actorUid,
    GroupMember target,
    GroupRole role,
  ) async {
    final member = _db.doc(FirestorePaths.member(groupId, target.uid));
    final audit = _db.collection(FirestorePaths.auditEvents(groupId)).doc();
    try {
      await _db.runTransaction((tx) async {
        _checkMember((await tx.get(member)).data(), target);
        if (target.role == GroupRole.owner ||
            role == GroupRole.owner ||
            target.role == role ||
            (actorUid == target.uid && role == GroupRole.admin)) {
          throw _conflict;
        }
        if (role == GroupRole.admin) await _checkPerson(tx, groupId, target);
        final now = FieldValue.serverTimestamp();
        tx.update(member, {
          'role': role.name,
          'updatedAt': now,
          'lastAuditEventId': audit.id,
        });
        tx.set(audit, {
          'action': 'member.roleChanged',
          'entityType': 'member',
          'entityId': target.uid,
          'actorUid': actorUid,
          'createdAt': now,
          'before': _summary(target, target.role),
          'after': _summary(target, role),
        });
      });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> transfer(
    Group group,
    GroupMember owner,
    GroupMember recipient,
  ) async {
    final root = _db.doc(FirestorePaths.group(group.id));
    final former = _db.doc(FirestorePaths.member(group.id, owner.uid));
    final next = _db.doc(FirestorePaths.member(group.id, recipient.uid));
    final audit = _db.collection(FirestorePaths.auditEvents(group.id)).doc();
    try {
      await _db.runTransaction((tx) async {
        final current = (await tx.get(root)).data();
        _checkMember((await tx.get(former)).data(), owner);
        _checkMember((await tx.get(next)).data(), recipient);
        if (current?['updatedAt'] != Timestamp.fromDate(group.updatedAt) ||
            current?['name'] != group.name ||
            current?['isActive'] != true ||
            owner.role != GroupRole.owner ||
            recipient.role == GroupRole.owner ||
            owner.uid == recipient.uid) {
          throw _conflict;
        }
        await _checkPerson(tx, group.id, recipient);
        final now = FieldValue.serverTimestamp();
        tx.update(former, {
          'role': 'member',
          'updatedAt': now,
          'lastAuditEventId': audit.id,
        });
        tx.update(next, {
          'role': 'owner',
          'updatedAt': now,
          'lastAuditEventId': audit.id,
        });
        tx.update(root, {
          'updatedAt': now,
          'updatedBy': owner.uid,
          'lastAuditEventId': audit.id,
        });
        tx.set(audit, {
          'action': 'group.ownershipTransferred',
          'entityType': 'group',
          'entityId': group.id,
          'actorUid': owner.uid,
          'createdAt': now,
          'before': {'ownerUid': owner.uid, 'groupName': group.name},
          'after': {'ownerUid': recipient.uid, 'groupName': group.name},
        });
      });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }
}
