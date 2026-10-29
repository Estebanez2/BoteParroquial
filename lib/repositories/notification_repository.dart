import '../core/errors/app_failure.dart';
import '../models/group_notification.dart';
import '../services/notification_service.dart';

final class NotificationRepository {
  const NotificationRepository(this._service);
  final NotificationService _service;
  void _validate(String groupId, String uid) {
    if (groupId.isEmpty ||
        uid.isEmpty ||
        groupId.contains('/') ||
        uid.contains('/')) {
      throw const AppFailure(
        FailureCode.invalidData,
        'El espacio de avisos no es válido.',
      );
    }
  }

  Stream<List<GroupNotification>> watchInbox(String groupId, String uid) {
    _validate(groupId, uid);
    return _service.watchInbox(groupId, uid).map((items) {
      if (items.any((n) => n.groupId != groupId || n.recipientUid != uid)) {
        throw const AppFailure(
          FailureCode.permissionDenied,
          'Los avisos no pertenecen a esta cuenta y grupo.',
        );
      }
      return List.unmodifiable(items);
    });
  }

  Stream<bool> watchQuotaPushEnabled(String groupId, String uid) {
    _validate(groupId, uid);
    return _service.watchQuotaPushEnabled(groupId, uid);
  }

  Future<void> setQuotaPushEnabled(String groupId, String uid, bool enabled) {
    _validate(groupId, uid);
    return _service.setQuotaPushEnabled(groupId, uid, enabled);
  }

  Stream<bool> watchActivityPushEnabled(
    String groupId,
    String uid,
    ActivityNotificationCategory category,
  ) {
    _validate(groupId, uid);
    final service = _service;
    return service is ActivityNotificationService
        ? (service as ActivityNotificationService).watchActivityPushEnabled(
            groupId,
            uid,
            category,
          )
        : Stream.value(true);
  }

  Future<void> setActivityPushEnabled(
    String groupId,
    String uid,
    ActivityNotificationCategory category,
    bool enabled,
  ) {
    _validate(groupId, uid);
    final service = _service;
    if (service is! ActivityNotificationService) {
      throw const AppFailure(
        FailureCode.configuration,
        'Las preferencias de actividad no están disponibles.',
      );
    }
    return (service as ActivityNotificationService).setActivityPushEnabled(
      groupId,
      uid,
      category,
      enabled,
    );
  }

  Future<void> markRead(String groupId, String uid, String id) {
    _validate(groupId, uid);
    if (id.isEmpty || id.contains('/')) {
      throw const AppFailure(FailureCode.invalidData, 'El aviso no es válido.');
    }
    return _service.markRead(groupId, uid, id);
  }
}
