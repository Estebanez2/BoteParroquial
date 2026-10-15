import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../models/group_member.dart';
import '../../../models/person.dart';
import '../../../repositories/person_repository.dart';
import '../../../services/firestore_person_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../groups/providers/group_providers.dart';

final personRepositoryProvider = Provider<PersonRepository>(
  (ref) =>
      PersonRepository(FirestorePersonService(ref.watch(firestoreProvider))),
);
final personsProvider = StreamProvider.autoDispose.family<List<Person>, String>(
  (ref, groupId) {
    final group = ref.watch(groupProvider(groupId));
    if (group.isLoading) return const Stream.empty();
    if (group.hasError) return Stream.error(group.error!, group.stackTrace);
    if (group.asData?.value == null) return Stream.value(const []);
    return ref.watch(personRepositoryProvider).watchPersons(groupId);
  },
  retry: (_, _) => null,
);

final canManagePersonsProvider = Provider.autoDispose.family<bool, String>((
  ref,
  groupId,
) {
  final member = ref.watch(currentMembershipProvider(groupId));
  final group = ref.watch(groupProvider(groupId));
  if (group.isLoading ||
      group.hasError ||
      group.asData?.value == null ||
      member == null) {
    return false;
  }
  if (member.role == GroupRole.owner) return true;
  if (member.role != GroupRole.admin || member.personId == null) return false;
  final persons = ref.watch(personsProvider(groupId));
  return !persons.isLoading &&
      !persons.hasError &&
      (persons.asData?.value.any(
            (p) => p.id == member.personId && p.isActive,
          ) ??
          false);
});

final personControllerProvider = NotifierProvider.autoDispose
    .family<PersonController, AsyncValue<void>, String>(PersonController.new);

class PersonController extends Notifier<AsyncValue<void>> {
  PersonController(this.groupId);
  final String groupId;
  @override
  AsyncValue<void> build() => const AsyncData(null);
  String? validateName(String? value) => PersonRepository.nameError(value);
  String? validateNotes(String? value) => PersonRepository.notesError(value);
  void clearError() {
    if (!state.isLoading) state = const AsyncData(null);
  }

  Future<bool> _perform(
    Future<void> Function(PersonRepository, String) action,
  ) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final session = ref.read(authStateProvider);
      final user = session.isLoading || session.hasError
          ? null
          : session.asData?.value;
      if (user == null || !ref.read(canManagePersonsProvider(groupId))) {
        throw const AppFailure(
          FailureCode.permissionDenied,
          'Ya no tienes permiso para gestionar estas personas.',
        );
      }
      await action(ref.read(personRepositoryProvider), user.uid);
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return false;
    }
  }

  Future<bool> save({Person? person, required String name, String? notes}) =>
      _perform(
        (repo, uid) => person == null
            ? repo.create(groupId, uid, name, notes)
            : repo.edit(groupId, uid, person, name, notes),
      );
  Future<bool> setActive(Person person, bool active) =>
      _perform((repo, uid) => repo.setActive(groupId, uid, person, active));
}
