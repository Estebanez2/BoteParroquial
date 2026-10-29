import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../models/report_comparison.dart';
import '../../../repositories/report_comparison_repository.dart';
import '../../groups/providers/group_providers.dart';
import '../../movements/providers/movement_providers.dart';
import '../../persons/providers/person_providers.dart';
import '../../quotas/providers/quota_providers.dart';
import 'quota_report_providers.dart';
import 'report_providers.dart';

final reportComparisonRepositoryProvider = Provider(
  (ref) => const ReportComparisonRepository(),
);

final reportComparisonProvider = Provider.autoDispose
    .family<AsyncValue<PeriodComparison?>, String>((ref, id) {
      final group = ref.watch(groupProvider(id));
      if (group.hasError) {
        return AsyncError(group.error!, group.stackTrace ?? StackTrace.current);
      }
      if (group.isLoading) return const AsyncLoading();
      final value = group.asData?.value;
      if (value == null || ref.watch(currentMembershipProvider(id)) == null) {
        return AsyncError(
          const AppFailure(
            FailureCode.permissionDenied,
            'Este grupo no está disponible.',
          ),
          StackTrace.current,
        );
      }
      final people = ref.watch(personsProvider(id)),
          movements = ref.watch(movementsProvider(id)),
          rules = ref.watch(quotaRulesProvider(id)),
          periods = ref.watch(groupQuotaPeriodsProvider(id)),
          allocations = ref.watch(groupQuotaAllocationsProvider(id));
      for (final state in <AsyncValue<Object?>>[
        people,
        movements,
        rules,
        periods,
        allocations,
      ]) {
        if (state.hasError) {
          return AsyncError(
            state.error!,
            state.stackTrace ?? StackTrace.current,
          );
        }
        if (state.isLoading || !state.hasValue) return const AsyncLoading();
      }
      try {
        return AsyncData(
          ref
              .watch(reportComparisonRepositoryProvider)
              .summarize(
                groupId: id,
                selection: ref.watch(reportSelectionProvider(id)),
                today: ref
                    .watch(groupCalendarRepositoryProvider)
                    .today(value.timeZone),
                persons: people.requireValue,
                movements: movements.requireValue,
                rules: rules.requireValue,
                periods: periods.requireValue,
                allocations: allocations.requireValue,
                quotaRepository: ref.watch(quotaReportRepositoryProvider),
              ),
        );
      } catch (error, stack) {
        return AsyncError(error, stack);
      }
    });
