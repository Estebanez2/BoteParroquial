import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../models/dashboard_summary.dart';
import '../../../repositories/dashboard_repository.dart';
import '../../groups/providers/group_providers.dart';
import '../../movements/providers/movement_providers.dart';
import '../../persons/providers/person_providers.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => const DashboardRepository(),
);
final dashboardProvider = Provider.autoDispose
    .family<AsyncValue<DashboardSummary>, String>((ref, groupId) {
      final group = ref.watch(groupProvider(groupId));
      final membership = ref.watch(currentMembershipProvider(groupId));
      if (group.isLoading) return const AsyncLoading();
      if (group.hasError) {
        return AsyncError(group.error!, group.stackTrace ?? StackTrace.current);
      }
      if (group.asData?.value == null || membership == null) {
        return AsyncError(
          const AppFailure(
            FailureCode.permissionDenied,
            'No tienes acceso al resumen de este grupo.',
          ),
          StackTrace.current,
        );
      }
      final movements = ref.watch(movementsProvider(groupId));
      final persons = ref.watch(personsProvider(groupId));
      if (movements.hasError) {
        return AsyncError(
          movements.error!,
          movements.stackTrace ?? StackTrace.current,
        );
      }
      if (persons.hasError) {
        return AsyncError(
          persons.error!,
          persons.stackTrace ?? StackTrace.current,
        );
      }
      if (movements.isLoading || persons.isLoading) return const AsyncLoading();
      final money = movements.asData?.value, people = persons.asData?.value;
      if (money == null || people == null) return const AsyncLoading();
      try {
        return AsyncData(
          ref
              .watch(dashboardRepositoryProvider)
              .summarize(groupId, money, people),
        );
      } catch (error, stack) {
        return AsyncError(error, stack);
      }
    });
