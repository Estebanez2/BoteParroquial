import '../models/participation_period.dart';
import '../models/quota_allocation.dart';

/// Group-scoped reads shared by dashboard and reports; no financial writes.
abstract interface class GroupQuotaService {
  Stream<List<ParticipationPeriod>> watchPeriods(String groupId);
  Stream<List<QuotaAllocation>> watchAllocations(String groupId);
}
