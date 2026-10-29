class InvitationCode {
  const InvitationCode({required this.groupId, required this.secret});
  final String groupId, secret;
  String get value => '$groupId.$secret';
  static InvitationCode? parse(String text) {
    final parts = text.trim().split('.');
    if (parts.length != 2 ||
        !RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(parts[0]) ||
        !RegExp(r'^[A-Za-z0-9_-]{32}$').hasMatch(parts[1])) {
      return null;
    }
    return InvitationCode(groupId: parts[0], secret: parts[1]);
  }
}

class InvitationSettings {
  const InvitationSettings({
    required this.code,
    required this.enabled,
    required this.requiresApproval,
    required this.updatedAt,
  });
  final InvitationCode code;
  final bool enabled, requiresApproval;
  final DateTime updatedAt;
}

class InvitationPreview {
  const InvitationPreview({
    required this.code,
    required this.groupName,
    required this.currency,
    required this.requiresApproval,
    this.isReadmission = false,
  });
  final InvitationCode code;
  final String groupName, currency;
  final bool requiresApproval;
  final bool isReadmission;
}

enum JoinRequestStatus { pending, approved, rejected }

class GroupJoinRequest {
  const GroupJoinRequest({
    required this.uid,
    required this.displayName,
    required this.status,
    required this.updatedAt,
  });
  final String uid, displayName;
  final JoinRequestStatus status;
  final DateTime updatedAt;
}
