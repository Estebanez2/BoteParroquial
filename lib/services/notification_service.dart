import '../models/group_notification.dart';

abstract interface class NotificationService {
  Stream<List<GroupNotification>> watchInbox(String groupId, String uid);
  Stream<bool> watchQuotaPushEnabled(String groupId, String uid);
  Future<void> setQuotaPushEnabled(String groupId, String uid, bool enabled);
  Future<void> markRead(String groupId, String uid, String notificationId);
  Future<void> registerDevice(
    String uid,
    String token,
    String platform,
    List<String> oldIds,
  );
  Future<void> unregisterDevices(String uid, List<String> ids);
}

abstract interface class ActivityNotificationService {
  Stream<bool> watchActivityPushEnabled(
    String groupId,
    String uid,
    ActivityNotificationCategory category,
  );
  Future<void> setActivityPushEnabled(
    String groupId,
    String uid,
    ActivityNotificationCategory category,
    bool enabled,
  );
}

abstract interface class PushMessagingService {
  String? get currentUid;
  String get platform;
  Future<bool> authorized({bool request = false});
  Future<String?> token();
  Future<void> stop();
  Stream<void> get tokenChanges;
  Stream<NotificationOpen> get opened;
  Future<NotificationOpen?> initialOpen();
}

abstract interface class PushRegistrationService {
  Future<PushRegistration?> read();
  Future<void> write(PushRegistration registration);
  Future<void> clear();
}
