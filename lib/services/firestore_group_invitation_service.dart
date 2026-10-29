import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';
import '../models/group_invitation.dart';
import '../models/group_member.dart';
import 'group_invitation_service.dart';

class FirestoreGroupInvitationService implements GroupInvitationService {
  const FirestoreGroupInvitationService(this._db);
  final FirebaseFirestore _db;
  static const _conflict = AppFailure(
    FailureCode.invalidData,
    'Estos datos han cambiado. Actualiza la pantalla antes de continuar.',
  );
  static const _invalid = AppFailure(
    FailureCode.invalidData,
    'La información de acceso al grupo no tiene un formato válido.',
  );
  AppFailure _failure(FirebaseException error) => switch (error.code) {
    'unavailable' || 'deadline-exceeded' => const AppFailure(
      FailureCode.network,
      'Se necesita conexión para confirmar esta operación. Actualiza antes de repetirla.',
    ),
    'permission-denied' || 'unauthenticated' => const AppFailure(
      FailureCode.permissionDenied,
      'No tienes permiso o la invitación ya no está disponible.',
    ),
    _ => const AppFailure(
      FailureCode.unknown,
      'No se pudo confirmar el cambio. Actualiza y revisa su estado antes de repetirlo.',
    ),
  };
  DocumentReference<Map<String, dynamic>> _settings(String groupId) =>
      _db.doc(FirestorePaths.invitationSettings(groupId));
  Map<String, Object?> _settingsSummary(Map<String, dynamic> data) => {
    'enabled': data['enabled'],
    'requiresApproval': data['requiresApproval'],
  };
  Map<String, Object?> _requestSummary(Map<String, dynamic> data) => {
    'uid': data['uid'],
    'displayName': data['displayName'],
    'status': data['status'],
  };
  Map<String, Object?> _memberSummary(Map<String, dynamic> data) => {
    'uid': data['uid'],
    'role': data['role'],
    'status': data['status'],
    'personId': data['personId'],
  };
  DateTime _date(Object? value) {
    if (value is! Timestamp) throw _invalid;
    return value.toDate().toUtc();
  }

  String _text(Object? value) {
    if (value is! String || value.isEmpty) throw _invalid;
    return value;
  }

  @override
  Stream<InvitationSettings?> watchSettings(String groupId) async* {
    try {
      yield* _settings(groupId)
          .snapshots(includeMetadataChanges: true)
          .where((s) => !s.metadata.hasPendingWrites)
          .map((doc) {
            final data = doc.data();
            if (data == null) return null;
            if (data['enabled'] is! bool || data['requiresApproval'] is! bool) {
              throw _invalid;
            }
            return InvitationSettings(
              code: InvitationCode(
                groupId: groupId,
                secret: _text(data['code']),
              ),
              enabled: data['enabled'] as bool,
              requiresApproval: data['requiresApproval'] as bool,
              updatedAt: _date(data['updatedAt']),
            );
          });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Stream<List<GroupJoinRequest>> watchRequests(String groupId) async* {
    try {
      yield* _db
          .collection(FirestorePaths.joinRequests(groupId))
          .where('status', isEqualTo: 'pending')
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) {
            final result =
                snapshot.docs
                    .where((doc) => !doc.metadata.hasPendingWrites)
                    .map((doc) {
                      final data = doc.data();
                      if (data['uid'] != doc.id ||
                          data['status'] != 'pending') {
                        throw _invalid;
                      }
                      return GroupJoinRequest(
                        uid: doc.id,
                        displayName: _text(data['displayName']),
                        status: JoinRequestStatus.pending,
                        updatedAt: _date(data['updatedAt']),
                      );
                    })
                    .toList()
                  ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
            return List.unmodifiable(result);
          });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<InvitationPreview> preview(InvitationCode code, String uid) async {
    try {
      final data =
          (await _db
                  .doc(FirestorePaths.invitation(code.groupId, code.secret))
                  .get(const GetOptions(source: Source.server)))
              .data();
      if (data == null || data['requiresApproval'] is! bool) throw _invalid;
      final member =
          (await _db
                  .doc(FirestorePaths.member(code.groupId, uid))
                  .get(const GetOptions(source: Source.server)))
              .data();
      final readmission = member?['status'] == 'inactive';
      return InvitationPreview(
        code: code,
        groupName: _text(data['groupName']),
        currency: _text(data['currency']),
        requiresApproval: data['requiresApproval'] == true || readmission,
        isReadmission: readmission,
      );
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> configure(
    String groupId,
    String uid, {
    required String newCode,
    required bool enabled,
    required bool requiresApproval,
    InvitationSettings? original,
  }) async {
    final config = _settings(groupId),
        invite = _db.doc(FirestorePaths.invitation(groupId, newCode));
    final audit = _db.collection(FirestorePaths.auditEvents(groupId)).doc();
    try {
      await _db.runTransaction((tx) async {
        final before = (await tx.get(config)).data();
        final group = (await tx.get(
          _db.doc(FirestorePaths.group(groupId)),
        )).data();
        final oldPreview = (await tx.get(invite)).data();
        if (group == null ||
            (original == null
                ? before != null
                : before?['updatedAt'] !=
                      Timestamp.fromDate(original.updatedAt)) ||
            (before?['code'] != newCode && oldPreview != null)) {
          throw _conflict;
        }
        final now = FieldValue.serverTimestamp();
        final after = {
          'code': newCode,
          'enabled': enabled,
          'requiresApproval': requiresApproval,
          'updatedBy': uid,
          'updatedAt': now,
          'lastAuditEventId': audit.id,
        };
        tx.set(config, after);
        tx.set(invite, {
          'groupName': group['name'],
          'currency': group['currency'],
          'requiresApproval': requiresApproval,
          'createdAt': oldPreview?['createdAt'] ?? now,
          'updatedAt': now,
        });
        tx.set(audit, {
          'action': 'invitation.changed',
          'entityType': 'invitation',
          'entityId': 'current',
          'actorUid': uid,
          'createdAt': now,
          'before': before == null ? null : _settingsSummary(before),
          'after': {
            ..._settingsSummary(after),
            'regenerated': before?['code'] != newCode,
          },
        });
      });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<JoinRequestStatus> submit(
    InvitationPreview preview,
    String uid,
    String displayName,
  ) async {
    final groupId = preview.code.groupId;
    final request = _db.doc(FirestorePaths.joinRequest(groupId, uid)),
        member = _db.doc(FirestorePaths.member(groupId, uid));
    final audit = _db.collection(FirestorePaths.auditEvents(groupId)).doc();
    try {
      return await _db.runTransaction((tx) async {
        final before = (await tx.get(request)).data();
        final oldMember = (await tx.get(member)).data();
        if (oldMember?['status'] == 'active') return JoinRequestStatus.approved;
        if (oldMember != null &&
            (oldMember['status'] != 'inactive' ||
                oldMember['role'] == 'owner')) {
          throw _conflict;
        }
        if (before?['status'] == 'pending' &&
            before?['code'] == preview.code.secret) {
          return JoinRequestStatus.pending;
        }
        final current = (await tx.get(
          _db.doc(FirestorePaths.invitation(groupId, preview.code.secret)),
        )).data();
        if (current == null || current['requiresApproval'] is! bool) {
          throw _invalid;
        }
        final pending =
            current['requiresApproval'] == true || oldMember != null;
        final now = FieldValue.serverTimestamp();
        final after = {
          'uid': uid,
          'displayName': displayName,
          'code': preview.code.secret,
          'status': pending ? 'pending' : 'approved',
          'createdAt': before?['createdAt'] ?? now,
          'updatedAt': now,
          'reviewedBy': pending ? null : uid,
          'reviewedAt': pending ? null : now,
          'lastAuditEventId': audit.id,
        };
        tx.set(request, after);
        if (!pending) {
          tx.set(member, {
            'uid': uid,
            'displayName': displayName,
            'role': 'member',
            'status': 'active',
            'personId': null,
            'joinedAt': now,
            'updatedAt': now,
            'lastAuditEventId': audit.id,
          });
        }
        tx.set(audit, {
          'action': pending ? 'join.requested' : 'join.accepted',
          'entityType': 'joinRequest',
          'entityId': uid,
          'actorUid': uid,
          'createdAt': now,
          'before': before == null ? null : _requestSummary(before),
          'after': _requestSummary(after),
        });
        return pending ? JoinRequestStatus.pending : JoinRequestStatus.approved;
      });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> decide(
    String groupId,
    String uid,
    GroupJoinRequest request,
    bool approve,
  ) async {
    final target = _db.doc(FirestorePaths.joinRequest(groupId, request.uid)),
        member = _db.doc(FirestorePaths.member(groupId, request.uid));
    final audit = _db.collection(FirestorePaths.auditEvents(groupId)).doc();
    try {
      await _db.runTransaction((tx) async {
        final before = (await tx.get(target)).data(),
            oldMember = (await tx.get(member)).data();
        if (before?['status'] == (approve ? 'approved' : 'rejected') &&
            (!approve || oldMember?['status'] == 'active')) {
          return;
        }
        if (before?['status'] != 'pending' ||
            before?['updatedAt'] != Timestamp.fromDate(request.updatedAt) ||
            oldMember?['role'] == 'owner') {
          throw _conflict;
        }
        if (approve && oldMember != null && oldMember['status'] != 'inactive') {
          throw _conflict;
        }
        final now = FieldValue.serverTimestamp();
        final after = {
          ...before!,
          'status': approve ? 'approved' : 'rejected',
          'reviewedBy': uid,
          'reviewedAt': now,
          'updatedAt': now,
          'lastAuditEventId': audit.id,
        };
        tx.update(target, after);
        if (approve) {
          tx.set(member, {
            'uid': request.uid,
            'displayName': before['displayName'],
            'role': 'member',
            'status': 'active',
            'personId': oldMember?['personId'],
            'joinedAt': oldMember?['joinedAt'] ?? now,
            'updatedAt': now,
            'lastAuditEventId': audit.id,
          });
        }
        tx.set(audit, {
          'action': approve ? 'join.approved' : 'join.rejected',
          'entityType': 'joinRequest',
          'entityId': request.uid,
          'actorUid': uid,
          'createdAt': now,
          'before': _requestSummary(before),
          'after': _requestSummary(after),
        });
      });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> remove(String groupId, String uid, GroupMember target) async {
    final member = _db.doc(FirestorePaths.member(groupId, target.uid)),
        audit = _db.collection(FirestorePaths.auditEvents(groupId)).doc();
    try {
      await _db.runTransaction((tx) async {
        final before = (await tx.get(member)).data();
        if (before?['status'] == 'inactive') return;
        if (before == null ||
            before['role'] == 'owner' ||
            before['updatedAt'] != Timestamp.fromDate(target.updatedAt)) {
          throw _conflict;
        }
        final now = FieldValue.serverTimestamp();
        final after = {
          ...before,
          'role': 'member',
          'status': 'inactive',
          'updatedAt': now,
          'lastAuditEventId': audit.id,
        };
        tx.update(member, after);
        tx.set(audit, {
          'action': uid == target.uid ? 'member.left' : 'member.removed',
          'entityType': 'member',
          'entityId': target.uid,
          'actorUid': uid,
          'createdAt': now,
          'before': _memberSummary(before),
          'after': _memberSummary(after),
        });
      });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }
}
