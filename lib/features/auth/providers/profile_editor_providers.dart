import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../models/user_profile.dart';
import '../../../repositories/profile_editor_repository.dart';
import '../../../services/firestore_profile_editor_service.dart';
import 'auth_providers.dart';

final profileEditorRepositoryProvider = Provider(
  (ref) => ProfileEditorRepository(
    FirestoreProfileEditorService(ref.watch(firestoreProvider)),
  ),
);
final profileEditorProvider =
    NotifierProvider.autoDispose<ProfileEditorController, AsyncValue<void>>(
      ProfileEditorController.new,
    );

class ProfileEditorController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);
  String? validateName(String? name) => ProfileEditorRepository.nameError(name);
  Future<bool> save(UserProfile original, String name) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final user = ref.read(authStateProvider).asData?.value;
      if (user == null) {
        throw const AppFailure(
          FailureCode.permissionDenied,
          'Tu sesión ha cambiado.',
        );
      }
      await ref
          .read(profileEditorRepositoryProvider)
          .rename(user.uid, original, name);
      if (ref.mounted) {
        ref.invalidate(userProfileProvider);
        state = const AsyncData(null);
      }
      return true;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return false;
    }
  }
}
