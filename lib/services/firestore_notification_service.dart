import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../core/errors/app_failure.dart';
import '../models/group_notification.dart';
import 'notification_service.dart';

final class FirestoreNotificationService
    implements NotificationService, ActivityNotificationService {
  const FirestoreNotificationService(this._db);
  final FirebaseFirestore _db;
  static AppFailure _failure(Object error) => AppFailure(
    error is FirebaseException && error.code == 'unavailable'
        ? FailureCode.network
        : FailureCode.permissionDenied,
    'No pudimos confirmar los avisos. Comprueba tu conexión y tu acceso al grupo.',
  );
  Stream<T> _guard<T>(Stream<T> stream) async* {
    try {
      yield* stream;
    } on FirebaseException catch (e) {
      throw _failure(e);
    }
  }

  DocumentReference<Map<String, dynamic>> _preference(
    String group,
    String uid,
  ) => _db.doc('groups/$group/members/$uid/notificationPreferences/reminders');
  @override
  Stream<bool> watchQuotaPushEnabled(String groupId, String uid) => _guard(
    _preference(
      groupId,
      uid,
    ).snapshots().map((doc) => doc.data()?['quotaPushEnabled'] != false),
  );
  @override
  Future<void> setQuotaPushEnabled(
    String groupId,
    String uid,
    bool enabled,
  ) async {
    try {
      final target = _preference(groupId, uid);
      await _db.runTransaction((tx) async {
        await tx.get(target);
        tx.set(target, {
          'quotaPushEnabled': enabled,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Stream<List<GroupNotification>> watchInbox(String groupId, String uid) =>
      _guard(
        _db
            .collection('groups/$groupId/notifications')
            .where('recipientUid', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots()
            .map(
              (snapshot) => [
                for (final doc in snapshot.docs)
                  _parse(groupId, doc.id, doc.data()),
              ],
            ),
      );
  @override
  Stream<bool> watchActivityPushEnabled(
    String groupId,
    String uid,
    ActivityNotificationCategory category,
  ) => _guard(
    _db
        .doc(
          'groups/$groupId/members/$uid/notificationPreferences/${category.name}',
        )
        .snapshots()
        .map((doc) => doc.data()?['pushEnabled'] != false),
  );

  @override
  Future<void> setActivityPushEnabled(
    String groupId,
    String uid,
    ActivityNotificationCategory category,
    bool enabled,
  ) async {
    try {
      final doc = _db.doc(
        'groups/$groupId/members/$uid/notificationPreferences/${category.name}',
      );
      await _db.runTransaction((tx) async {
        await tx.get(doc);
        tx.set(doc, {
          'pushEnabled': enabled,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw _failure(e);
    }
  }

  GroupNotification _parse(
    String groupId,
    String id,
    Map<String, dynamic> data,
  ) {
    final kind = GroupNotificationKind.values
        .where((k) => k.name == data['kind'])
        .firstOrNull;
    if (kind == null ||
        data['recipientUid'] is! String ||
        data['title'] is! String ||
        data['body'] is! String ||
        data['createdAt'] is! Timestamp ||
        (data['readAt'] != null && data['readAt'] is! Timestamp)) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Un aviso no tiene un formato válido. Actualiza la bandeja.',
      );
    }
    return GroupNotification(
      id: id,
      groupId: groupId,
      recipientUid: data['recipientUid'] as String,
      kind: kind,
      title: data['title'] as String,
      body: data['body'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  Future<void> markRead(
    String groupId,
    String uid,
    String notificationId,
  ) async {
    try {
      final target = _db.doc('groups/$groupId/notifications/$notificationId');
      await _db.runTransaction((tx) async {
        final before = (await tx.get(target)).data();
        if (before == null || before['recipientUid'] != uid) {
          throw const AppFailure(
            FailureCode.permissionDenied,
            'Este aviso no está disponible para tu cuenta.',
          );
        }
        if (before['readAt'] == null) {
          tx.update(target, {'readAt': FieldValue.serverTimestamp()});
        }
      });
    } on FirebaseException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<void> registerDevice(
    String uid,
    String token,
    String platform,
    List<String> oldIds,
  ) async {
    if (oldIds.length > 100) {
      throw const AppFailure(
        FailureCode.configuration,
        'Retira los avisos de este móvil antes de volver a activarlos.',
      );
    }
    try {
      final id = sha256.convert(utf8.encode(token)).toString();
      final target = _db.doc('users/$uid/pushDevices/$id');
      await _db.runTransaction((tx) async {
        final previous = (await tx.get(target)).data();
        tx.set(target, {
          'token': token,
          'platform': platform,
          'createdAt': previous?['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        for (final old in oldIds.where((old) => old != id)) {
          tx.delete(_db.doc('users/$uid/pushDevices/$old'));
        }
      });
    } on FirebaseException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<void> unregisterDevices(String uid, List<String> ids) async {
    try {
      // Read a private document online before confirming even an empty registry.
      for (var start = 0; start < ids.length; start += 100) {
        final chunk = ids.skip(start).take(100).toList();
        await _db.runTransaction((tx) async {
          await tx.get(_db.doc('users/$uid/pushDevices/${chunk.first}'));
          for (final id in chunk) {
            tx.delete(_db.doc('users/$uid/pushDevices/$id'));
          }
        });
      }
    } on FirebaseException catch (e) {
      throw _failure(e);
    }
  }
}
