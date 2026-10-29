import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../models/economic_report.dart';
import '../../../models/participation_period.dart';
import '../../../models/quota_allocation.dart';
import '../../../models/quota_report.dart';
import '../../../repositories/quota_report_repository.dart';
import '../../../services/firestore_group_quota_service.dart';
import '../../groups/providers/group_providers.dart';
import '../../movements/providers/movement_providers.dart';
import '../../persons/providers/person_providers.dart';
import '../../quotas/providers/quota_providers.dart';
import 'report_providers.dart';

final quotaReportRepositoryProvider = Provider(
  (ref) => QuotaReportRepository(
    FirestoreGroupQuotaService(ref.watch(firestoreProvider)),
  ),
);
final groupQuotaPeriodsProvider = StreamProvider.autoDispose
    .family<List<ParticipationPeriod>, String>((ref, id) {
      if (ref.watch(currentMembershipProvider(id)) == null) {
        return Stream.value([]);
      }
      final group = ref.watch(groupProvider(id));
      if (group.isLoading) return const Stream.empty();
      if (group.hasError) return Stream.error(group.error!, group.stackTrace);
      if (group.asData?.value == null) {
        return Stream.value([]);
      }
      return ref.watch(quotaReportRepositoryProvider).watchPeriods(id);
    }, retry: (_, _) => null);
final groupQuotaAllocationsProvider = StreamProvider.autoDispose
    .family<List<QuotaAllocation>, String>((ref, id) {
      if (ref.watch(currentMembershipProvider(id)) == null) {
        return Stream.value([]);
      }
      final group = ref.watch(groupProvider(id));
      if (group.isLoading) return const Stream.empty();
      if (group.hasError) return Stream.error(group.error!, group.stackTrace);
      if (group.asData?.value == null) {
        return Stream.value([]);
      }
      return ref.watch(quotaReportRepositoryProvider).watchAllocations(id);
    }, retry: (_, _) => null);
final quotaReportProvider = Provider.autoDispose
    .family<AsyncValue<QuotaReport>, String>(
      (ref, id) => _report(ref, id, false),
    );
final dashboardQuotaReportProvider = Provider.autoDispose
    .family<AsyncValue<QuotaReport>, String>(
      (ref, id) => _report(ref, id, true),
    );

AsyncValue<QuotaReport> _report(Ref ref, String id, bool dashboard) {
  final group = ref.watch(groupProvider(id));
  if (group.isLoading) return const AsyncLoading();
  if (group.hasError) {
    return AsyncError(group.error!, group.stackTrace ?? StackTrace.current);
  }
  if (group.asData?.value == null ||
      ref.watch(currentMembershipProvider(id)) == null) {
    return AsyncError(
      const AppFailure(
        FailureCode.permissionDenied,
        'Este grupo no está disponible.',
      ),
      StackTrace.current,
    );
  }
  final now = ref.watch(quotaMonthProvider(id));
  final selection = dashboard
      ? ReportSelection(year: now.year, month: now.month)
      : ref.watch(reportSelectionProvider(id));
  final people = ref.watch(personsProvider(id)),
      money = ref.watch(
        dashboard ? quotaSourceMovementsProvider(id) : movementsProvider(id),
      ),
      rules = ref.watch(quotaRulesProvider(id)),
      periods = ref.watch(groupQuotaPeriodsProvider(id)),
      allocations = ref.watch(groupQuotaAllocationsProvider(id));
  for (final data in <AsyncValue<Object?>>[
    people,
    money,
    rules,
    periods,
    allocations,
  ]) {
    if (data.hasError) {
      return AsyncError(data.error!, data.stackTrace ?? StackTrace.current);
    }
    if (data.isLoading || !data.hasValue) return const AsyncLoading();
  }
  try {
    return AsyncData(
      ref
          .watch(quotaReportRepositoryProvider)
          .summarize(
            groupId: id,
            currentMonth: now,
            selection: selection,
            persons: people.requireValue,
            movements: money.requireValue,
            rules: rules.requireValue,
            periods: periods.requireValue,
            allocations: allocations.requireValue,
          ),
    );
  } catch (e, s) {
    return AsyncError(e, s);
  }
}
