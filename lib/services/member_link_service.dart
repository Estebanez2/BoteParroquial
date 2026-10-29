import '../models/group_member.dart';
import '../models/person.dart';

abstract interface class MemberLinkService {
  Future<void> change(
    String groupId,
    String actorUid,
    GroupMember target,
    Person? previous,
    Person? next,
  );
}
