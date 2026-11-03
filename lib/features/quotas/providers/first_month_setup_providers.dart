import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../models/person.dart';
import '../../../models/year_month.dart';
import '../../../repositories/participation_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../persons/providers/person_providers.dart';
import '../../reports/providers/quota_report_providers.dart';
import 'quota_providers.dart';

final firstMonthCandidatesProvider = Provider.autoDispose
    .family<AsyncValue<List<Person>>, String>((ref, groupId) {
      final persons = ref.watch(personsProvider(groupId));
      final periods = ref.watch(groupQuotaPeriodsProvider(groupId));
      if (persons.hasError || periods.hasError) {
        return AsyncError(persons.error ?? periods.error!, StackTrace.current);
      }
      if (persons.isLoading ||
          periods.isLoading ||
          !persons.hasValue ||
          !periods.hasValue) {
        return const AsyncLoading();
      }
      return AsyncData(
        ParticipationRepository.awaitingFirstMonth(
          groupId,
          persons.requireValue,
          periods.requireValue,
        ),
      );
    });

final firstMonthSetupProvider = NotifierProvider.autoDispose
    .family<
      FirstMonthSetupController,
      AsyncValue<FirstMonthSetupResult?>,
      String
    >(FirstMonthSetupController.new);

class FirstMonthSetupController
    extends Notifier<AsyncValue<FirstMonthSetupResult?>> {
  FirstMonthSetupController(this.groupId);
  final String groupId;
  @override
  AsyncValue<FirstMonthSetupResult?> build() => const AsyncData(null);

  Future<FirstMonthSetupResult?> save(Set<String> ids, YearMonth month) async {
    if (state.isLoading) return null;
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    bool authorized() =>
        ref.mounted &&
        uid != null &&
        ref.read(authStateProvider).asData?.value?.uid == uid &&
        ref.read(canManagePersonsProvider(groupId));
    state = const AsyncLoading();
    try {
      if (!authorized()) {
        throw const AppFailure(
          FailureCode.permissionDenied,
          'Necesitas permiso de gestión.',
        );
      }
      final pending = ref.read(firstMonthCandidatesProvider(groupId));
      if (pending.isLoading || pending.hasError || !pending.hasValue) {
        throw const AppFailure(
          FailureCode.invalidData,
          'Espera a que se comprueben las personas pendientes.',
        );
      }
      final selected = pending.requireValue
          .where((p) => ids.contains(p.id))
          .toList();
      if (selected.length != ids.length) {
        throw const AppFailure(
          FailureCode.invalidData,
          'Alguna persona ya ha cambiado. Revisa la selección antes de guardar.',
        );
      }
      final result = await ref
          .read(participationRepositoryProvider)
          .startFirstMonths(
            groupId: groupId,
            actorUid: uid!,
            persons: selected,
            month: month,
            currentMonth: ref.read(quotaMonthProvider(groupId)),
            canContinue: authorized,
          );
      if (!ref.mounted) return null;
      if (!authorized()) {
        state = AsyncError(
          const AppFailure(
            FailureCode.permissionDenied,
            'Tu sesión o tus permisos han cambiado. Revisa las personas antes de continuar.',
          ),
          StackTrace.current,
        );
        return null;
      }
      state = AsyncData(result);
      return result;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return null;
    }
  }
}
