import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';
import '../models/group.dart';
import '../models/group_input.dart';
import 'group_management_service.dart';

class FirestoreGroupManagementService implements GroupManagementService {
  const FirestoreGroupManagementService(this._db);
  final FirebaseFirestore _db;
  static const _conflict = AppFailure(
    FailureCode.invalidData,
    'El grupo ha cambiado o este envío ya existe con otros datos. Vuelve a abrirlo.',
  );
  static AppFailure _failure(FirebaseException error) => switch (error.code) {
    'resource-exhausted' => firestoreQuotaFailure,
    'permission-denied' || 'unauthenticated' => const AppFailure(
      FailureCode.permissionDenied,
      'No tienes permiso para guardar este grupo.',
    ),
    'unavailable' || 'deadline-exceeded' => const AppFailure(
      FailureCode.network,
      'No se pudo confirmar el grupo. Comprueba la conexión y reintenta sin cerrar el formulario.',
    ),
    _ => const AppFailure(
      FailureCode.unknown,
      'No se pudo guardar el grupo. Revisa tus espacios antes de crear otro.',
    ),
  };
  @override
  String newId() => _db.collection('groups').doc().id;

  Map<String, String?> _identity(String name, String? description) => {
    'name': name,
    'description': description,
  };

  @override
  Future<void> create(
    String groupId,
    String uid,
    String displayName,
    GroupInput input,
  ) async {
    final group = _db.doc(FirestorePaths.group(groupId));
    try {
      await _db.runTransaction((tx) async {
        final existing = (await tx.get(group)).data();
        if (existing != null) {
          final member = (await tx.get(
            _db.doc(FirestorePaths.member(groupId, uid)),
          )).data();
          if (existing['createdBy'] != uid ||
              existing['name'] != input.name ||
              existing['description'] != input.description ||
              existing['currency'] != input.currency ||
              existing['timeZone'] != input.timeZone ||
              member?['personId'] !=
                  (input.createOwnerPerson ? 'owner' : null) ||
              member?['role'] != 'owner' ||
              member?['status'] != 'active') {
            throw _conflict;
          }
          return;
        }
        final now = FieldValue.serverTimestamp();
        tx.set(group, {
          'name': input.name,
          'description': input.description,
          'currency': input.currency,
          'timeZone': input.timeZone,
          'isActive': true,
          'createdBy': uid,
          'updatedBy': uid,
          'createdAt': now,
          'updatedAt': now,
          'lastAuditEventId': 'created',
        });
        tx.set(_db.doc(FirestorePaths.member(groupId, uid)), {
          'uid': uid,
          'displayName': displayName,
          'role': 'owner',
          'status': 'active',
          'joinedAt': now,
          'updatedAt': now,
          'personId': input.createOwnerPerson ? 'owner' : null,
        });
        if (input.createOwnerPerson) {
          tx.set(_db.doc(FirestorePaths.person(groupId, 'owner')), {
            'historyGuardVersion': 1,
            'linkedUid': uid,
            'displayName': displayName,
            'notes': null,
            'isActive': true,
            'createdBy': uid,
            'updatedBy': uid,
            'createdAt': now,
            'updatedAt': now,
          });
        }
        tx.set(_db.doc(FirestorePaths.auditEvent(groupId, 'created')), {
          'action': 'group.created',
          'actorUid': uid,
          'createdAt': now,
          'entityId': groupId,
          'before': null,
          'after': _identity(input.name, input.description),
        });
      });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> update(
    Group group,
    String uid,
    String name,
    String description,
  ) async {
    final target = _db.doc(FirestorePaths.group(group.id));
    final audit = _db.collection(FirestorePaths.auditEvents(group.id)).doc();
    try {
      await _db.runTransaction((tx) async {
        final before = (await tx.get(target)).data();
        if (before == null ||
            before['updatedAt'] != Timestamp.fromDate(group.updatedAt)) {
          throw _conflict;
        }
        final settings = (await tx.get(
          _db.doc(FirestorePaths.invitationSettings(group.id)),
        )).data();
        final invite = settings == null
            ? null
            : _db.doc(
                FirestorePaths.invitation(group.id, settings['code'] as String),
              );
        final now = FieldValue.serverTimestamp();
        tx.update(target, {
          'name': name,
          'description': description,
          'updatedBy': uid,
          'updatedAt': now,
          'lastAuditEventId': audit.id,
        });
        tx.set(audit, {
          'action': 'group.updated',
          'actorUid': uid,
          'entityId': group.id,
          'createdAt': now,
          'before': _identity(
            before['name'] as String,
            before['description'] as String?,
          ),
          'after': _identity(name, description),
        });
        if (invite != null) {
          tx.update(invite, {'groupName': name, 'updatedAt': now});
        }
      });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }
}
