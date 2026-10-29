import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../repositories/account_lifecycle_repository.dart';
import '../../../services/firebase_account_lifecycle_service.dart';
import '../../groups/providers/group_invitation_providers.dart';
import 'auth_providers.dart';

final accountLifecycleRepositoryProvider = Provider(
  (ref) => AccountLifecycleRepository(
    FirebaseAccountLifecycleService(
      ref.watch(firestoreProvider),
      ref.watch(firebaseAuthProvider),
      ref.watch(supabaseConnectionProvider),
    ),
    ref.watch(authRepositoryProvider),
    ref.watch(groupInvitationRepositoryProvider),
  ),
);
final accountClosingProvider = FutureProvider.autoDispose<bool>((ref) async {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return false;
  return ref.watch(accountLifecycleRepositoryProvider).isClosing(uid);
}, retry: (_, _) => null);
final accountClosureControllerProvider =
    NotifierProvider.autoDispose<AccountClosureController, AsyncValue<bool?>>(
      AccountClosureController.new,
    );

class AccountClosureController extends Notifier<AsyncValue<bool?>> {
  @override
  AsyncValue<bool?> build() => const AsyncData(null);
  Future<bool?> close() async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    try {
      final uid = ref.read(authStateProvider).asData?.value?.uid;
      if (uid == null) {
        throw const AppFailure(FailureCode.permissionDenied, 'Inicia sesión.');
      }
      final done = await ref
          .read(accountLifecycleRepositoryProvider)
          .close(uid);
      final currentUid = ref.mounted
          ? ref.read(authStateProvider).asData?.value?.uid
          : null;
      if (currentUid != uid && !(done && currentUid == null)) return null;
      if (ref.mounted) {
        state = AsyncData(done);
        ref.invalidate(accountClosingProvider);
      }
      return done;
    } catch (e, s) {
      if (ref.mounted) state = AsyncError(e, s);
      return null;
    }
  }
}
