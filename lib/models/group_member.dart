enum GroupRole { owner, admin, member }

class GroupMember {
  const GroupMember({
    required this.groupId,
    required this.uid,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.joinedAt,
    required this.updatedAt,
    this.personId,
  });
  final String groupId;
  final String uid;
  final String displayName;
  final GroupRole role;
  final bool isActive;
  final String? personId;
  final DateTime joinedAt;
  final DateTime updatedAt;
}
