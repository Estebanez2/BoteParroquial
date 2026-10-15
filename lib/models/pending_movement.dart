import 'movement.dart';

/// A confirmed user intention, retained until its server result is known.
class PendingMovement {
  const PendingMovement({
    required this.groupId,
    required this.actorUid,
    required this.id,
    required this.input,
    this.original,
    this.reason,
    this.cancel = false,
  });
  final String groupId, actorUid, id;
  final MovementInput input;
  final Movement? original;
  final String? reason;
  final bool cancel;
}
