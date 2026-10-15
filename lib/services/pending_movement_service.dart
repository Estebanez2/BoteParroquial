import '../models/pending_movement.dart';

abstract interface class PendingMovementService {
  Future<PendingMovement?> read(String uid, String groupId);
  Future<void> write(PendingMovement submission);
  Future<void> clear(String uid, String groupId, String expectedId);
}
