import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../models/movement.dart';
import '../../../models/quota_allocation.dart';
import '../../../models/quota_settlement.dart';
import '../../../models/year_month.dart';
import '../../../repositories/allocation_repository.dart';
import '../../../repositories/initial_quota_repository.dart';
import '../../../models/initial_quota_assignment.dart';
import '../../../repositories/quota_settlement_repository.dart';
import '../../../services/firestore_allocation_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../groups/providers/group_providers.dart';
import '../../movements/providers/movement_providers.dart';
import 'quota_providers.dart';

final allocationRepositoryProvider = Provider(
  (ref) => AllocationRepository(
    FirestoreAllocationService(ref.watch(firestoreProvider)),
  ),
);
final allocationsProvider = StreamProvider.autoDispose
    .family<List<QuotaAllocation>, (String, String)>((ref, key) {
      final group = ref.watch(groupProvider(key.$1));
      if (group.isLoading) return const Stream.empty();
      if (group.hasError) return Stream.error(group.error!);
      return group.asData?.value == null
          ? Stream.value([])
          : ref
                .watch(allocationRepositoryProvider)
                .watchAllocations(key.$1, key.$2);
    }, retry: (_, _) => null);

final personQuotaSettlementProvider = Provider.autoDispose
    .family<AsyncValue<PersonQuotaSettlement>, (String, String)>((ref, key) {
      final rules = ref.watch(quotaRulesProvider(key.$1));
      final periods = ref.watch(participationPeriodsProvider(key));
      final movements = ref.watch(movementsProvider(key.$1));
      final allocations = ref.watch(allocationsProvider(key));
      for (final value in <AsyncValue<Object?>>[
        rules,
        periods,
        movements,
        allocations,
      ]) {
        if (value.hasError) {
          return AsyncError(
            value.error!,
            value.stackTrace ?? StackTrace.current,
          );
        }
        if (value.isLoading || !value.hasValue) return const AsyncLoading();
      }
      try {
        return AsyncData(
          const QuotaSettlementRepository().summarize(
            groupId: key.$1,
            personId: key.$2,
            currentMonth: ref.watch(quotaMonthProvider(key.$1)),
            rules: rules.requireValue,
            periods: periods.requireValue,
            movements: movements.requireValue,
            allocations: allocations.requireValue,
          ),
        );
      } catch (e, s) {
        return AsyncError(e, s);
      }
    });

final personQuotaYearProvider = Provider.autoDispose
    .family<AsyncValue<List<MonthQuotaPayment>>, (String, String, int)>(
      (ref, key) => ref
          .watch(personQuotaSettlementProvider((key.$1, key.$2)))
          .whenData(
            (s) => List.unmodifiable(
              s.months.where((m) => m.month.year == key.$3),
            ),
          ),
    );

final incomeAllocationViewProvider = Provider.autoDispose
    .family<AsyncValue<IncomeAllocationView>, (String, String)>((ref, key) {
      final movements = ref.watch(movementsProvider(key.$1));
      if (movements.hasError) {
        return AsyncError(
          movements.error!,
          movements.stackTrace ?? StackTrace.current,
        );
      }
      if (movements.isLoading || !movements.hasValue) {
        return const AsyncLoading();
      }
      final income = movements.requireValue
          .where((m) => m.id == key.$2)
          .firstOrNull;
      if (income == null ||
          income.input.type != MovementType.income ||
          income.input.personId == null) {
        return AsyncError(
          const AppFailure(
            FailureCode.invalidData,
            'Elige un ingreso asociado a una persona.',
          ),
          StackTrace.current,
        );
      }
      final personKey = (key.$1, income.input.personId!);
      final settlement = ref.watch(personQuotaSettlementProvider(personKey));
      final allocations = ref.watch(allocationsProvider(personKey));
      return settlement.whenData((s) {
        final rows = allocations.requireValue;
        return IncomeAllocationView(
          movement: income,
          settlement: s,
          allocations: rows.where((a) => a.movementId == income.id).toList()
            ..sort((a, b) => a.month.compareTo(b.month)),
          suggestions: const QuotaSettlementRepository().propose(
            s,
            income,
            rows,
          ),
        );
      });
    });

final allocationControllerProvider = NotifierProvider.autoDispose
    .family<AllocationController, AsyncValue<void>, String>(
      AllocationController.new,
    );

class AllocationController extends Notifier<AsyncValue<void>> {
  AllocationController(this.groupId);
  final String groupId;
  @override
  AsyncValue<void> build() => const AsyncData(null);
  static const _denied = AppFailure(
    FailureCode.permissionDenied,
    'Actualiza el grupo para comprobar tus permisos.',
  );
  ({
    InitialQuotaAssignment assignment,
    int overpaymentCents,
    int? expectedCents,
  })
  reviewInitial(String personId, YearMonth month, int? cents, int incomeCents) {
    if (ref.read(authStateProvider).asData?.value == null ||
        !ref.read(canManageMovementsProvider(groupId))) {
      throw _denied;
    }
    final key = (groupId, personId);
    return InitialQuotaRepository.review(
      groupId: groupId,
      personId: personId,
      month: month,
      cents: cents,
      incomeCents: incomeCents,
      periods: ref.read(participationPeriodsProvider(key)).requireValue,
      rules: ref.read(quotaRulesProvider(groupId)).requireValue,
      settlement: ref.read(personQuotaSettlementProvider(key)).requireValue,
    );
  }

  AllocationReview review(String movementId, YearMonth month, int? cents) {
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null || !ref.read(canManageMovementsProvider(groupId))) {
      throw _denied;
    }
    final view = ref
        .read(incomeAllocationViewProvider((groupId, movementId)))
        .requireValue;
    final personKey = (groupId, view.movement.input.personId!);
    return ref
        .read(allocationRepositoryProvider)
        .review(
          groupId: groupId,
          actorUid: uid,
          operationId: ref
              .read(allocationRepositoryProvider)
              .newOperationId(groupId),
          movement: view.movement,
          month: month,
          cents: cents,
          settlement: view.settlement,
          allocations: ref.read(allocationsProvider(personKey)).requireValue,
          periods: ref
              .read(participationPeriodsProvider(personKey))
              .requireValue,
          rules: ref.read(quotaRulesProvider(groupId)).requireValue,
        );
  }

  Future<bool> save(AllocationReview review) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    try {
      if (uid == null ||
          uid != review.change.actorUid ||
          !ref.read(canManageMovementsProvider(groupId))) {
        throw _denied;
      }
      await ref
          .read(allocationRepositoryProvider)
          .change(groupId, uid, review.change);
      if (!ref.mounted ||
          ref.read(authStateProvider).asData?.value?.uid != uid) {
        return false;
      }
      state = const AsyncData(null);
      return true;
    } catch (e, s) {
      if (ref.mounted) state = AsyncError(e, s);
      return false;
    }
  }
}
