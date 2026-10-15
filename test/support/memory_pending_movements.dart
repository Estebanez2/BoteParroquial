import 'package:bote_parroquial/models/pending_movement.dart';
import 'package:bote_parroquial/services/pending_movement_service.dart';

class MemoryPendingMovements implements PendingMovementService {
  final Map<(String, String), PendingMovement> entries = {};
  @override
  Future<PendingMovement?> read(String uid, String groupId) async =>
      entries[(uid, groupId)];
  @override
  Future<void> write(PendingMovement submission) async {
    entries[(submission.actorUid, submission.groupId)] = submission;
  }

  @override
  Future<void> clear(String uid, String groupId, String expectedId) async {
    if (entries[(uid, groupId)]?.id == expectedId) {
      entries.remove((uid, groupId));
    }
  }
}
