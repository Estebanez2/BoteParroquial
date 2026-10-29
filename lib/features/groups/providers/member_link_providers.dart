import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../models/group_member.dart';
import '../../../models/person.dart';
import '../../../repositories/member_link_repository.dart';
import '../../../services/firestore_member_link_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../persons/providers/person_providers.dart';
import 'group_management_providers.dart';
import 'group_providers.dart';

final memberLinkRepositoryProvider = Provider(
  (ref) => MemberLinkRepository(
    FirestoreMemberLinkService(ref.watch(firestoreProvider)),
  ),
);
final canEditMemberLinkProvider = Provider.autoDispose
    .family<bool, (String, GroupMember)>((ref, key) {
      final actor = ref.watch(currentMembershipProvider(key.$1));
      return actor != null &&
          ref.watch(canEditGroupProvider(key.$1)) &&
          key.$2.groupId == key.$1 &&
          (key.$2.role != GroupRole.owner || key.$2.uid == actor.uid);
    });
final unlinkedMembersProvider = Provider.autoDispose
    .family<List<GroupMember>, String>(
      (ref, id) =>
          (ref.watch(groupMembersProvider(id)).asData?.value ??
                  const <GroupMember>[])
              .where((member) => member.isActive && member.personId == null)
              .toList(growable: false),
    );
final memberLinkCandidatesProvider = Provider.autoDispose
    .family<List<Person>, (String, GroupMember)>(
      (ref, key) =>
          (ref.watch(personsProvider(key.$1)).asData?.value ?? const <Person>[])
              .where(
                (person) =>
                    (key.$2.isActive || person.id == key.$2.personId) &&
                    (person.linkedUid == null || person.id == key.$2.personId),
              )
              .toList(growable: false),
    );
final linkedPersonProvider = Provider.autoDispose
    .family<Person?, (String, GroupMember)>((ref, key) {
      for (final person
          in ref.watch(personsProvider(key.$1)).asData?.value ??
              const <Person>[]) {
        if (person.id == key.$2.personId) return person;
      }
      return null;
    });
final memberListFilterProvider = NotifierProvider.autoDispose
    .family<MemberListFilter, bool, String>(MemberListFilter.new);

class MemberListFilter extends Notifier<bool> {
  MemberListFilter(this.groupId);
  final String groupId;
  @override
  bool build() => false;
  void select(bool value) => state = value;
}

final visibleGroupMembersProvider = Provider.autoDispose
    .family<List<GroupMember>, String>(
      (ref, id) => ref.watch(memberListFilterProvider(id))
          ? ref.watch(unlinkedMembersProvider(id))
          : ref.watch(groupMembersProvider(id)).asData?.value ??
                const <GroupMember>[],
    );
final memberLinkControllerProvider = NotifierProvider.autoDispose
    .family<MemberLinkController, AsyncValue<void>, String>(
      MemberLinkController.new,
    );

class MemberLinkController extends Notifier<AsyncValue<void>> {
  MemberLinkController(this.groupId);
  final String groupId;
  @override
  AsyncValue<void> build() => const AsyncData(null);
  bool losesAdmin(GroupMember member, Person? next) =>
      MemberLinkRepository.losesAdmin(member, next);
  Future<bool> change(GroupMember target, Person? next) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final actor = ref.read(authStateProvider).asData?.value?.uid;
      if (actor == null ||
          !ref.read(canEditMemberLinkProvider((groupId, target)))) {
        throw const AppFailure(
          FailureCode.permissionDenied,
          'No puedes modificar este vínculo.',
        );
      }
      final persons = ref.read(personsProvider(groupId));
      if (!persons.hasValue || persons.isLoading || persons.hasError) {
        throw const AppFailure(
          FailureCode.invalidData,
          'Espera a que se actualicen las personas del grupo.',
        );
      }
      Person? previous;
      for (final person in persons.requireValue) {
        if (person.id == target.personId) previous = person;
      }
      await ref
          .read(memberLinkRepositoryProvider)
          .change(groupId, actor, target, previous, next);
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return false;
    }
  }
}
