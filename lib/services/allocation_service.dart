import '../models/quota_allocation.dart';

abstract interface class AllocationService {
  String newOperationId(String groupId);
  Stream<List<QuotaAllocation>> watchAllocations(
    String groupId,
    String personId,
  );
  Future<void> change(String groupId, String actorUid, AllocationChange change);
}
