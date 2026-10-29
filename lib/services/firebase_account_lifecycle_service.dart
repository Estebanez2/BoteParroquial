import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/errors/app_failure.dart';
import '../models/account_closure.dart';
import '../models/group_member.dart';
import 'account_lifecycle_service.dart';
import 'firestore_group_service.dart';
import 'supabase_connection_service.dart';

class FirebaseAccountLifecycleService implements AccountLifecycleService {
  const FirebaseAccountLifecycleService(this._db, this._auth, this._photos);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final SupabaseConnectionService _photos;
  static const _server = GetOptions(source: Source.server);
  static const _changed = AppFailure(
    FailureCode.permissionDenied,
    'La cuenta ha cambiado. Abre de nuevo la baja desde tu perfil.',
  );
  void _check(String uid) {
    if (_auth.currentUser?.uid != uid) throw _changed;
  }

  DocumentReference<Map<String, dynamic>> _task(String uid) =>
      _db.doc('users/$uid/accountLifecycle/current');
  @override
  Future<AccountClosure?> current(String uid) async {
    _check(uid);
    final data = (await _task(uid).get(_server)).data();
    _check(uid);
    if (data == null) return null;
    final groups = data['groupIds'];
    if (groups is! List || groups.any((v) => v is! String)) {
      throw const AppFailure(
        FailureCode.invalidData,
        'La baja tiene datos incompletos. No se ha borrado la cuenta.',
      );
    }
    return AccountClosure(
      preparing: data['status'] == 'preparing',
      groupIds: groups.cast<String>(),
      closingAt: (data['closingAt'] as Timestamp?)?.toDate().toUtc(),
    );
  }

  @override
  Future<List<GroupMember>> memberships(String uid) async {
    _check(uid);
    final rows = await _db
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .get(_server);
    _check(uid);
    return List.unmodifiable(rows.docs.map(FirestoreGroupService.parseMember));
  }

  @override
  Future<void> checkNoOwnedGroups(
    String uid,
    List<GroupMember> memberships,
  ) async {
    _check(uid);
    final pending = await _db
        .collection('users/$uid/groupDeletionTasks')
        .where('status', isEqualTo: 'deleting')
        .limit(1)
        .get(_server);
    if (pending.docs.isNotEmpty) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Termina primero la eliminación de grupos pendiente desde Inicio.',
      );
    }
    for (final member in memberships.where((m) => m.role == GroupRole.owner)) {
      final root = await _db.doc('groups/${member.groupId}').get(_server);
      if (root.exists) {
        throw const AppFailure(
          FailureCode.invalidData,
          'Todavía eres propietario de un grupo. Transfiere su propiedad o elimínalo antes de dar de baja la cuenta.',
        );
      }
    }
    _check(uid);
  }

  @override
  Future<void> begin(String uid, List<String> groups) async {
    _check(uid);
    if (groups.length > 1000) {
      throw const AppFailure(
        FailureCode.invalidData,
        'La baja supera el volumen que puede procesarse desde el móvil.',
      );
    }
    await _db.runTransaction((tx) async {
      final data = (await tx.get(_task(uid))).data();
      if (data != null) return;
      tx.set(_task(uid), {
        'groupIds': groups,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'preparing',
      });
    });
  }

  @override
  Future<AccountClosure> seal(String uid) async {
    // Memberships have been withdrawn; the marker blocks new groups/joins. Re-query
    // after that barrier, so a concurrent new membership cannot escape cleanup.
    final rows = await memberships(uid);
    if (rows.any((m) => m.isActive)) {
      await _task(uid).delete();
      throw const AppFailure(
        FailureCode.invalidData,
        'Se ha detectado un nuevo acceso mientras se preparaba la baja. Revisa tus grupos y repite; tu cuenta sigue disponible.',
      );
    }
    await _task(uid).update({
      'status': 'closing',
      'groupIds': rows.map((m) => m.groupId).toSet().toList(),
      'closingAt': FieldValue.serverTimestamp(),
    });
    final saved = await current(uid);
    if (saved == null) throw _changed;
    return saved;
  }

  @override
  Future<bool> cleanupAndDelete(String uid, AccountClosure closure) async {
    _check(uid);
    final anchor = closure.closingAt;
    if (anchor == null ||
        DateTime.now().toUtc().isBefore(
          anchor.add(const Duration(seconds: 30)),
        )) {
      return false;
    }
    var offset = 0;
    while (true) {
      final result = await _photos.client.functions.invoke(
        'lifecycle-cleanup',
        body: {'action': 'account', 'offset': offset},
      );
      _check(uid);
      final data = result.data;
      if (data is! Map || data['nextOffset'] is! int) {
        throw const AppFailure(
          FailureCode.network,
          'No se confirmó la limpieza de fotos. Reanuda la baja.',
        );
      }
      if (data['complete'] == true) break;
      final next = data['nextOffset'] as int;
      if (next <= offset || next > closure.groupIds.length) return false;
      offset = next;
    }
    while (true) {
      final page = await _db
          .collection('users/$uid/pushDevices')
          .limit(100)
          .get(_server);
      if (page.docs.isEmpty) break;
      final batch = _db.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      _check(uid);
    }
    while (true) {
      final page = await _db
          .collection('users/$uid/auditEvents')
          .limit(100)
          .get(_server);
      if (page.docs.isEmpty) break;
      final batch = _db.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      _check(uid);
    }
    await _db.doc('users/$uid').delete();
    _check(uid);
    // Keep the minimal closing marker on uncertain Auth deletion. This prevents
    // a relaunch from recreating the profile or granting new group access.
    await _auth.currentUser!.delete();
    return true;
  }
}
