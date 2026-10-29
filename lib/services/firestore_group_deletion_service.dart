import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase/supabase.dart' show FunctionException;
import '../core/errors/app_failure.dart';
import '../models/group_deletion.dart';
import 'firestore_movement_service.dart';
import 'group_deletion_service.dart';
import 'supabase_connection_service.dart';

class FirestoreGroupDeletionService implements GroupDeletionService {
  const FirestoreGroupDeletionService(this._db, this._photos);
  final FirebaseFirestore _db;
  final SupabaseConnectionService _photos;
  static const _server = GetOptions(source: Source.server);
  static const _denied = AppFailure(
    FailureCode.permissionDenied,
    'Solo el propietario actual puede eliminar este grupo.',
  );
  @override
  Future<GroupDeletionPreview> preview(String groupId, String uid) async {
    try {
      final group = (await _db.doc('groups/$groupId').get(_server)).data();
      final member =
          (await _db.doc('groups/$groupId/members/$uid').get(_server)).data();
      if (group == null ||
          group['isActive'] != true ||
          member?['role'] != 'owner' ||
          member?['status'] != 'active') {
        throw _denied;
      }
      final movements = await FirestoreMovementService(
        _db,
      ).loadMovements(groupId);
      final persons = await _db
          .collection('groups/$groupId/persons')
          .count()
          .get();
      final members = await _db
          .collection('groups/$groupId/members')
          .count()
          .get();
      final balance = movements.fold<BigInt>(
        BigInt.zero,
        (accumulator, m) => accumulator + BigInt.from(m.contributionCents),
      );
      if (BigInt.from(balance.toInt()) != balance) {
        throw const AppFailure(
          FailureCode.invalidData,
          'El saldo excede el intervalo admitido.',
        );
      }
      return GroupDeletionPreview(
        groupId: groupId,
        name: group['name'] as String,
        currency: group['currency'] as String,
        balanceCents: balance.toInt(),
        persons: persons.count ?? 0,
        members: members.count ?? 0,
        movements: movements.length,
      );
    } on FirebaseException {
      throw const AppFailure(
        FailureCode.network,
        'No se pudo comprobar el grupo en el servidor.',
      );
    }
  }

  @override
  Stream<List<GroupDeletionTask>> watchPending(String uid) => _db
      .collection('users/$uid/groupDeletionTasks')
      .snapshots()
      .map(
        (s) => List.unmodifiable([
          for (final doc in s.docs)
            if (doc.data()['status'] == 'deleting')
              GroupDeletionTask(
                groupId: doc.id,
                groupName: doc.data()['groupName'] as String,
              ),
        ]),
      );
  @override
  Future<bool> remove(String groupId, String uid, String exactName) async {
    final root = _db.doc('groups/$groupId'),
        task = _db.doc('users/$uid/groupDeletionTasks/$groupId');
    try {
      await _db.runTransaction((tx) async {
        final previous = (await tx.get(task)).data();
        if (previous?['status'] == 'done') return;
        final group = (await tx.get(root)).data();
        if (group == null || group['name'] != exactName) {
          throw const AppFailure(
            FailureCode.invalidData,
            'El nombre del grupo ha cambiado. Actualiza la pantalla antes de confirmar.',
          );
        }
        if (group['isActive'] == false) {
          if (group['deletionBy'] != uid || previous?['status'] != 'deleting') {
            throw _denied;
          }
          return;
        }
        final owner = (await tx.get(
          _db.doc('groups/$groupId/members/$uid'),
        )).data();
        if (owner?['role'] != 'owner' || owner?['status'] != 'active') {
          throw _denied;
        }
        final now = FieldValue.serverTimestamp();
        tx.update(root, {
          'isActive': false,
          'deletionBy': uid,
          'deletionName': exactName,
          'deletionStartedAt': now,
          'updatedBy': uid,
          'updatedAt': now,
        });
        tx.set(task, {
          'groupName': exactName,
          'status': 'deleting',
          'createdAt': now,
        });
      });
      final state = (await task.get(_server)).data();
      if (state?['status'] == 'done') return true;
      final locked = (await root.get(_server)).data();
      final started = locked?['deletionStartedAt'];
      if (started is! Timestamp) throw _denied;
      // Quiescence for requests/worker leases already in flight. Server Rules
      // enforce the same barrier; changing the phone clock cannot bypass it.
      if (DateTime.now().toUtc().isBefore(
        started.toDate().toUtc().add(const Duration(minutes: 3)),
      )) {
        return false;
      }
      final response = await _photos.client.functions.invoke(
        'lifecycle-cleanup',
        body: {'action': 'group', 'groupId': groupId},
      );
      if (response.data is! Map || response.data['complete'] != true) {
        return false;
      }
      // Explicit schema registry: nested collections are drained before parents.
      for (final collection in ['members', 'quotaRules']) {
        final nested = collection == 'members'
            ? 'notificationPreferences'
            : 'versions';
        while (true) {
          final page = await _db
              .collection('groups/$groupId/$collection')
              .limit(100)
              .get(_server);
          if (page.docs.isEmpty) break;
          for (final doc in page.docs) {
            await _drain(doc.reference.collection(nested));
          }
          final batch = _db.batch();
          for (final doc in page.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      }
      for (final collection in [
        'persons',
        'personHistory',
        'movements',
        'invitationSettings',
        'invitations',
        'joinRequests',
        'quotaSettings',
        'participationPeriods',
        'allocations',
        'allocationBalances',
        'notifications',
        'notificationDeliveries',
        'notificationDeviceStates',
        'notificationWorker',
        'auditEvents',
      ]) {
        await _drain(_db.collection('groups/$groupId/$collection'));
      }
      final batch = _db.batch();
      batch.delete(root);
      batch.update(task, {'status': 'done'});
      await batch.commit();
      return true;
    } on FirebaseException {
      throw const AppFailure(
        FailureCode.network,
        'La eliminación no ha terminado. El grupo permanece bloqueado; vuelve a verificar Google y reanuda desde Inicio.',
      );
    } on FunctionException {
      throw const AppFailure(
        FailureCode.network,
        'No se confirmó la limpieza de fotos. Reanuda la eliminación desde Inicio.',
      );
    }
  }

  Future<void> _drain(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final page = await collection.limit(100).get(_server);
      if (page.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
