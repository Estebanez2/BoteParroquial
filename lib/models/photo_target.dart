enum PhotoKind { account, group, member, person }

enum PhotoSource { gallery, camera }

/// Identity of a photo, independent of Firebase, Storage and Flutter.
class PhotoTarget {
  const PhotoTarget.account(String uid)
    : kind = PhotoKind.account,
      id = uid,
      groupId = null;
  const PhotoTarget.group(String group)
    : kind = PhotoKind.group,
      id = group,
      groupId = group;
  const PhotoTarget.member(String group, String uid)
    : kind = PhotoKind.member,
      id = uid,
      groupId = group;
  const PhotoTarget.person(String group, String personId)
    : kind = PhotoKind.person,
      id = personId,
      groupId = group;

  final PhotoKind kind;
  final String id;
  final String? groupId;

  @override
  bool operator ==(Object other) =>
      other is PhotoTarget &&
      other.kind == kind &&
      other.id == id &&
      other.groupId == groupId;
  @override
  int get hashCode => Object.hash(kind, id, groupId);
}

class PhotoAccess {
  const PhotoAccess({required this.canRead, required this.canEdit});
  const PhotoAccess.denied() : canRead = false, canEdit = false;
  final bool canRead;
  final bool canEdit;
}
