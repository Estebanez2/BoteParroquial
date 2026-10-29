import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../models/person.dart';
import '../../../models/trashed_person.dart';
import '../../../repositories/person_trash_repository.dart';
import '../../../services/firestore_person_trash_service.dart';
import '../../auth/providers/auth_providers.dart';
import 'person_providers.dart';

final personTrashRepositoryProvider = Provider(
  (ref) => PersonTrashRepository(
    FirestorePersonTrashService(
      ref.watch(firestoreProvider),
      ref.watch(supabaseConnectionProvider),
    ),
  ),
);
final personTrashProvider = StreamProvider.autoDispose
    .family<List<TrashedPerson>, String>((ref, groupId) {
      ref.watch(authStateProvider);
      if (!ref.watch(canManagePersonsProvider(groupId))) {
        return Stream.value(const []);
      }
      return ref.watch(personTrashRepositoryProvider).watch(groupId);
    }, retry: (_, _) => null);
final personTrashControllerProvider = NotifierProvider.autoDispose
    .family<PersonTrashController, AsyncValue<void>, String>(
      PersonTrashController.new,
    );

class PersonTrashController extends Notifier<AsyncValue<void>> {
  PersonTrashController(this.groupId);
  final String groupId;
  @override
  AsyncValue<void> build() => const AsyncData(null);
  Future<bool> _perform(
    Future<void> Function(PersonTrashRepository, String) action,
  ) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final uid = ref.read(authStateProvider).asData?.value?.uid;
      if (uid == null || !ref.read(canManagePersonsProvider(groupId))) {
        throw const AppFailure(
          FailureCode.permissionDenied,
          'Ya no puedes gestionar esta papelera.',
        );
      }
      await action(ref.read(personTrashRepositoryProvider), uid);
      if (!ref.mounted) return false;
      if (ref.read(authStateProvider).asData?.value?.uid != uid) {
        throw const AppFailure(FailureCode.cancelled, 'La sesión ha cambiado.');
      }
      state = const AsyncData(null);
      return true;
    } catch (e, s) {
      if (ref.mounted) state = AsyncError(e, s);
      return false;
    }
  }

  Future<bool> trash(Person person) =>
      _perform((repo, uid) => repo.trash(groupId, uid, person));
  Future<bool> restore(TrashedPerson person) =>
      _perform((repo, uid) => repo.restore(groupId, uid, person));
  Future<bool> purge(TrashedPerson person) =>
      _perform((repo, uid) => repo.purge(groupId, uid, person));
  bool canRestore(TrashedPerson person) => ref
      .read(personTrashRepositoryProvider)
      .canRestore(person, DateTime.now().toUtc());
}
