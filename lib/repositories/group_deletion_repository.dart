import '../core/errors/app_failure.dart';
import '../models/group_deletion.dart';
import '../services/group_deletion_service.dart';
import 'auth_repository.dart';

class GroupDeletionRepository {
  const GroupDeletionRepository(this._service, this._auth);
  final GroupDeletionService _service;
  final AuthRepository _auth;
  Future<GroupDeletionPreview> preview(String groupId, String uid) =>
      _service.preview(groupId, uid);
  Stream<List<GroupDeletionTask>> watchPending(String uid) =>
      _service.watchPending(uid);
  Future<bool> remove(
    String groupId,
    String uid,
    String expectedName,
    String typedName,
  ) async {
    if (typedName != expectedName) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Escribe el nombre exacto del grupo, respetando espacios y mayúsculas.',
      );
    }
    await _auth.reauthenticateWithGoogle(uid);
    return _service.remove(groupId, uid, expectedName);
  }
}
