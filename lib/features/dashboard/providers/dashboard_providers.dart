import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../models/dashboard_summary.dart';
import '../../../models/movement.dart';
import '../../../models/movement_cash_totals.dart';
import '../../../repositories/dashboard_repository.dart';
import '../../groups/providers/group_providers.dart';
import '../../movements/providers/movement_providers.dart';
import '../../persons/providers/person_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../quotas/providers/quota_providers.dart';

final dashboardCashProvider = StreamProvider.autoDispose
    .family<MovementCashTotals, String>((ref, id) {
      final uid = ref.watch(authStateProvider).asData?.value?.uid,
          group = ref.watch(groupProvider(id));
      if (group.isLoading) return const Stream.empty();
      if (group.hasError) return Stream.error(group.error!, group.stackTrace);
      if (uid == null || group.asData?.value == null) {
        return Stream.error(
          const AppFailure(
            FailureCode.permissionDenied,
            'No tienes acceso a esta caja.',
          ),
        );
      }
      final month = ref.watch(quotaMonthProvider(id));
      return ref
          .watch(movementRepositoryProvider)
          .watchCash(id, uid, DateTime.utc(month.year, month.month));
    }, retry: (_, _) => null);
final dashboardRecentProvider = StreamProvider.autoDispose
    .family<List<Movement>, String>((ref, id) {
      final group = ref.watch(groupProvider(id));
      if (group.isLoading) return const Stream.empty();
      if (group.hasError) return Stream.error(group.error!, group.stackTrace);
      if (group.asData?.value == null) return Stream.value(const []);
      return ref.watch(movementRepositoryProvider).watchRecent(id);
    }, retry: (_, _) => null);

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
      final movements = ref.watch(dashboardRecentProvider(groupId));
      final cash = ref.watch(dashboardCashProvider(groupId));
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
      if (cash.hasError) {
        return AsyncError(cash.error!, cash.stackTrace ?? StackTrace.current);
      }
      if (cash.isLoading || !cash.hasValue) return const AsyncLoading();
      if (movements.isLoading || persons.isLoading) return const AsyncLoading();
      final money = movements.asData?.value, people = persons.asData?.value;
      if (money == null || people == null) return const AsyncLoading();
      try {
        return AsyncData(
          ref
              .watch(dashboardRepositoryProvider)
              .fromCash(groupId, cash.requireValue, money, people),
        );
      } catch (error, stack) {
        return AsyncError(error, stack);
      }
    });
