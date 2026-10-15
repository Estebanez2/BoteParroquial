import '../models/group.dart';
import '../models/group_member.dart';

abstract interface class GroupService {
  Stream<List<GroupMember>> watchMemberships(String uid);
  Stream<Group?> watchGroup(String groupId);
  Stream<List<GroupMember>> watchMembers(String groupId);
}
