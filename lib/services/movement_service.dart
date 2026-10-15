import '../models/movement.dart';

abstract interface class MovementService {
  String newId(String groupId);
  Stream<List<Movement>> watchMovements(String groupId);
  Future<List<Movement>> loadMovements(String groupId);
  Future<void> save(
    String groupId,
    String id,
    String actorUid,
    MovementInput input, {
    Movement? original,
    String? reason,
  });
  Future<void> cancel(
    String groupId,
    Movement movement,
    String actorUid,
    String reason,
  );
}
