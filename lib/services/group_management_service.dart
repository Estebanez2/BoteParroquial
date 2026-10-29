import '../models/group.dart';
import '../models/group_input.dart';

abstract interface class GroupManagementService {
  String newId();
  Future<void> create(
    String groupId,
    String uid,
    String displayName,
    GroupInput input,
  );
  Future<void> update(Group group, String uid, String name, String description);
}
