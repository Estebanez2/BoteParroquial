import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../models/group.dart';
import '../../../models/group_input.dart';
import '../../../repositories/group_management_repository.dart';
import '../../../services/firestore_group_management_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../persons/providers/person_providers.dart';

final groupManagementRepositoryProvider = Provider<GroupManagementRepository>(
  (ref) => GroupManagementRepository(
    FirestoreGroupManagementService(ref.watch(firestoreProvider)),
  ),
);
final groupCurrenciesProvider = Provider(
  (ref) => GroupManagementRepository.currencies,
);
final groupTimeZonesProvider = Provider(
  (ref) => GroupManagementRepository.timeZones,
);
final canEditGroupProvider = Provider.autoDispose.family<bool, String>(
  (ref, id) => ref.watch(canManagePersonsProvider(id)),
);
final groupManagementControllerProvider = NotifierProvider.autoDispose
    .family<GroupManagementController, AsyncValue<void>, String>(
      GroupManagementController.new,
    );

class GroupManagementController extends Notifier<AsyncValue<void>> {
  GroupManagementController(this.groupId);
  final String groupId;
  @override
  AsyncValue<void> build() => const AsyncData(null);
  String newId() => ref.read(groupManagementRepositoryProvider).newId();
  String? validateName(String? value) =>
      GroupManagementRepository.nameError(value);
  String? validateDescription(String? value) =>
      GroupManagementRepository.descriptionError(value);
  Future<bool> save({
    required String name,
    required String description,
    Group? original,
    GroupInput? creation,
  }) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final user = ref.read(authStateProvider).asData?.value;
      if (user == null ||
          (original != null &&
              (original.id != groupId ||
                  !ref.read(canEditGroupProvider(groupId))))) {
        throw const AppFailure(
          FailureCode.permissionDenied,
          'Ya no tienes permiso para guardar este grupo.',
        );
      }
      final repository = ref.read(groupManagementRepositoryProvider);
      if (original != null) {
        await repository.update(original, user.uid, name, description);
      } else {
        if (creation == null) {
          throw const AppFailure(
            FailureCode.invalidData,
            'Completa los datos del grupo.',
          );
        }
        final profile = await ref.read(userProfileProvider.future);
        if (!ref.mounted ||
            profile?.uid != user.uid ||
            ref.read(authStateProvider).asData?.value?.uid != user.uid) {
          throw const AppFailure(
            FailureCode.permissionDenied,
            'Tu sesión ha cambiado. Abre el formulario de nuevo.',
          );
        }
        await repository.create(
          groupId,
          user.uid,
          profile!.displayName,
          creation,
        );
      }
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return false;
    }
  }
}
