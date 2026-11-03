import '../models/initial_quota_assignment.dart';
import '../models/movement.dart';

/// Capability for atomic income + first allocation, never sequential writes.
abstract interface class InitialQuotaMovementService {
  Future<void> saveWithInitialQuota(
    String groupId,
    String id,
    String actorUid,
    MovementInput input,
    InitialQuotaAssignment assignment,
  );
  Future<bool> initialQuotaApplied(
    String groupId,
    String id,
    String actorUid,
    InitialQuotaAssignment assignment,
  );
}
