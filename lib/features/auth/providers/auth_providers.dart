import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../models/auth_user.dart';
import '../../../models/user_profile.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/user_profile_repository.dart';
import '../../../services/firebase_auth_service.dart';
import '../../../services/firestore_user_profile_service.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => DefaultAuthRepository(
    FirebaseAuthService(ref.watch(firebaseAuthProvider), GoogleSignIn.instance),
  ),
);

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => DefaultUserProfileRepository(
    FirestoreUserProfileService(ref.watch(firestoreProvider)),
  ),
);

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  if (!ref.watch(firebaseStartupProvider).isReady) return Stream.value(null);
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final userProfileProvider = FutureProvider.autoDispose<UserProfile?>(
  (ref) async {
    final user = await ref.watch(authStateProvider.future);
    if (user == null) return null;
    return ref.watch(userProfileRepositoryProvider).ensureProfile(user);
  },
  // Retry explicitly rather than repeatedly writing on failure.
  retry: (retryCount, error) => null,
);

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn() => _perform(() async {
    await ref.read(authRepositoryProvider).signInWithGoogle();
  });

  Future<void> signOut() =>
      _perform(() => ref.read(authRepositoryProvider).signOut());

  void retrySession() => ref.invalidate(authStateProvider);
  void retryProfile() => ref.invalidate(userProfileProvider);

  Future<void> _perform(Future<void> Function() action) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    try {
      await action();
      if (ref.mounted) state = const AsyncData(null);
    } catch (error, stackTrace) {
      if (!ref.mounted) return;
      if (error is AppFailure && error.code == FailureCode.cancelled) {
        state = const AsyncData(null);
      } else {
        state = AsyncError(error, stackTrace);
      }
    }
  }
}
