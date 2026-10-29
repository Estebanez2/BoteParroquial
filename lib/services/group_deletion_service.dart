import '../models/group_deletion.dart';

abstract interface class GroupDeletionService {
  Future<GroupDeletionPreview> preview(String groupId, String uid);
  Stream<List<GroupDeletionTask>> watchPending(String uid);
  Future<bool> remove(String groupId, String uid, String exactName);
}
