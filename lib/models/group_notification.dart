enum GroupNotificationKind {
  quotaReminder,
  unlinkedQuotaSummary,
  joinRequested,
  memberAccepted,
  memberJoined,
  unlinkedMember,
  linkChanged,
  adminGranted,
  adminLost,
  incomeAssociated,
  withdrawalAssociated,
  quotaChanged,
  ownershipTransferred,
  movementCancelled,
  invitationRegenerated,
}

enum ActivityNotificationCategory { economic, informative }

final class GroupNotification {
  const GroupNotification({
    required this.id,
    required this.groupId,
    required this.recipientUid,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.readAt,
  });
  final String id, groupId, recipientUid, title, body;
  final GroupNotificationKind kind;
  final DateTime createdAt;
  final DateTime? readAt;
}

final class NotificationOpen {
  const NotificationOpen({required this.groupId, required this.recipientUid});
  final String groupId, recipientUid;
}

/// Private local intent: only UID and token hashes, never the delivery token.
final class PushRegistration {
  PushRegistration({
    required this.uid,
    required Iterable<String> tokenIds,
    this.enabled = true,
  }) : tokenIds = List.unmodifiable(tokenIds);
  final String uid;
  final List<String> tokenIds;
  final bool enabled;
}
