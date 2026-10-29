import '../models/group.dart';
import '../models/group_member.dart';

abstract interface class MemberRoleService {
  Future<void> changeRole(
    String groupId,
    String actorUid,
    GroupMember target,
    GroupRole role,
  );
  Future<void> transfer(Group group, GroupMember owner, GroupMember recipient);
}
