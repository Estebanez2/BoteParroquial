import '../services/group_sync_service.dart';

class GroupSyncRepository {
  const GroupSyncRepository(this._service);
  final GroupSyncService _service;
  Stream<bool> watchServerConfirmation(String groupId, String uid) =>
      _service.watchServerConfirmation(groupId, uid);
}
