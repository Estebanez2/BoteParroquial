import '../models/group.dart';
import '../models/group_member.dart';
import '../services/group_service.dart';

abstract interface class GroupRepository {
  Stream<List<GroupMember>> watchMemberships(String uid);
  Stream<Group?> watchGroup(String groupId);
  Stream<List<GroupMember>> watchMembers(String groupId);
}

class DefaultGroupRepository implements GroupRepository {
  const DefaultGroupRepository(this._service);
  final GroupService _service;
  @override
  Stream<List<GroupMember>> watchMemberships(String uid) => _service
      .watchMemberships(uid)
      .map(
        (members) => List.unmodifiable(
          members.where((member) => member.uid == uid && member.isActive),
        ),
      );
  @override
  Stream<Group?> watchGroup(String groupId) => _service.watchGroup(groupId);
  @override
  Stream<List<GroupMember>> watchMembers(String groupId) =>
      _service.watchMembers(groupId);
}
