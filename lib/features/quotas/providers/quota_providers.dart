import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../models/person.dart';
import '../../../models/quota_rule.dart';
import '../../../models/participation_period.dart';
import '../../../models/year_month.dart';
import '../../../models/quota_expectation.dart';
import '../../../repositories/quota_expectation_repository.dart';
import '../../../repositories/quota_repository.dart';
import '../../../repositories/participation_repository.dart';
import '../../../services/firestore_quota_service.dart';
import '../../../services/firestore_participation_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../groups/providers/group_providers.dart';
import '../../persons/providers/person_providers.dart';
import '../../movements/providers/movement_providers.dart';

final quotaRepositoryProvider = Provider(
  (ref) => QuotaRepository(FirestoreQuotaService(ref.watch(firestoreProvider))),
);
final participationRepositoryProvider = Provider(
  (ref) => ParticipationRepository(
    FirestoreParticipationService(ref.watch(firestoreProvider)),
  ),
);
final quotaMonthProvider = Provider.autoDispose.family<YearMonth, String>((
  ref,
  id,
) {
  final group = ref.watch(groupProvider(id)).requireValue;
  if (group == null) {
    throw const AppFailure(
      FailureCode.permissionDenied,
      'Grupo no disponible.',
    );
  }
  return YearMonth.fromDate(
    ref.watch(groupCalendarRepositoryProvider).today(group.timeZone),
  );
});
final quotaRulesProvider = StreamProvider.autoDispose
    .family<List<QuotaRule>, String>((ref, id) {
      final group = ref.watch(groupProvider(id));
      if (group.isLoading) return const Stream.empty();
      if (group.hasError) return Stream.error(group.error!);
      return group.asData?.value == null
          ? Stream.value([])
          : ref.watch(quotaRepositoryProvider).watchRules(id);
    }, retry: (_, _) => null);
final quotaVersionsProvider = StreamProvider.autoDispose
    .family<List<QuotaRule>, (String, String)>((ref, key) {
      final group = ref.watch(groupProvider(key.$1));
      if (group.isLoading) return const Stream.empty();
      if (group.hasError) return Stream.error(group.error!);
      return group.asData?.value == null
          ? Stream.value([])
          : ref.watch(quotaRepositoryProvider).watchVersions(key.$1, key.$2);
    }, retry: (_, _) => null);
final participationPeriodsProvider = StreamProvider.autoDispose
    .family<List<ParticipationPeriod>, (String, String)>((ref, key) {
      final group = ref.watch(groupProvider(key.$1));
      if (group.isLoading) return const Stream.empty();
      if (group.hasError) return Stream.error(group.error!);
      return group.asData?.value == null
          ? Stream.value([])
          : ref
                .watch(participationRepositoryProvider)
                .watchPeriods(key.$1, key.$2);
    }, retry: (_, _) => null);
final quotaControllerProvider = NotifierProvider.autoDispose
    .family<QuotaController, AsyncValue<void>, String>(QuotaController.new);
final currentQuotaRuleProvider = Provider.autoDispose
    .family<QuotaRule?, String>(
      (ref, id) => QuotaRepository.atMonth(
        ref.watch(quotaRulesProvider(id)).asData?.value ?? [],
        ref.watch(quotaMonthProvider(id)),
      ),
    );
final personQuotaExpectationProvider = Provider.autoDispose
    .family<AsyncValue<PersonQuotaExpectation>, (String, String, int)>((
      ref,
      key,
    ) {
      final rules = ref.watch(quotaRulesProvider(key.$1));
      final periods = ref.watch(participationPeriodsProvider((key.$1, key.$2)));
      if (rules.hasError) {
        return AsyncError(rules.error!, rules.stackTrace ?? StackTrace.current);
      }
      if (periods.hasError) {
        return AsyncError(
          periods.error!,
          periods.stackTrace ?? StackTrace.current,
        );
      }
      if (rules.isLoading ||
          periods.isLoading ||
          !rules.hasValue ||
          !periods.hasValue) {
        return const AsyncLoading();
      }
      try {
        final now = ref.watch(quotaMonthProvider(key.$1));
        return AsyncData(
          const QuotaExpectationRepository().summarize(
            groupId: key.$1,
            personId: key.$2,
            firstMonth: YearMonth(key.$3, 1),
            lastMonth: key.$3 == now.year ? now : YearMonth(key.$3, 12),
            rules: rules.requireValue,
            periods: periods.requireValue,
          ),
        );
      } catch (e, s) {
        return AsyncError(e, s);
      }
    });

class QuotaController extends Notifier<AsyncValue<void>> {
  QuotaController(this.groupId);
  final String groupId;
  @override
  AsyncValue<void> build() => const AsyncData(null);
  void clearError() {
    if (!state.isLoading) state = const AsyncData(null);
  }

  String? validateAmount(int? cents) => QuotaRepository.amountError(cents);
  YearMonth _currentMonth() {
    final group = ref.read(groupProvider(groupId)).requireValue;
    if (group == null) throw _denied;
    return YearMonth.fromDate(
      ref.read(groupCalendarRepositoryProvider).today(group.timeZone),
    );
  }

  static const _denied = AppFailure(
    FailureCode.permissionDenied,
    'Actualiza el grupo para comprobar tus permisos.',
  );
  Future<bool> _perform(Future<void> Function(String) action) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final uid = ref.read(authStateProvider).asData?.value?.uid;
      if (uid == null || !ref.read(canManagePersonsProvider(groupId))) {
        throw _denied;
      }
      await action(uid);
      if (!ref.mounted ||
          ref.read(authStateProvider).asData?.value?.uid != uid) {
        return false;
      }
      state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return false;
    }
  }

  Future<bool> saveRule(
    YearMonth month,
    int? cents,
    List<QuotaRule> observed,
  ) => _perform(
    (uid) => ref
        .read(quotaRepositoryProvider)
        .saveRule(
          groupId: groupId,
          actorUid: uid,
          month: month,
          cents: cents,
          currentMonth: _currentMonth(),
          rules: observed,
        ),
  );
  Future<bool> participation(Person person, YearMonth month, bool starting) =>
      _perform((uid) async {
        final periods = ref.read(
          participationPeriodsProvider((groupId, person.id)),
        );
        if (periods.isLoading || periods.hasError || !periods.hasValue) {
          throw const AppFailure(
            FailureCode.invalidData,
            'Espera a que se actualicen los periodos.',
          );
        }
        ParticipationPeriod? previous;
        for (final period in periods.requireValue) {
          if (period.id == person.lastParticipationPeriodId) previous = period;
        }
        await ref
            .read(participationRepositoryProvider)
            .change(
              groupId: groupId,
              actorUid: uid,
              person: person,
              previous: previous,
              month: month,
              currentMonth: _currentMonth(),
              starting: starting,
            );
      });
}
