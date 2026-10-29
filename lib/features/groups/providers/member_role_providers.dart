import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../models/group.dart';
import '../../../models/group_member.dart';
import '../../../models/person.dart';
import '../../../repositories/member_role_repository.dart';
import '../../../services/firestore_member_role_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../persons/providers/person_providers.dart';
import 'group_management_providers.dart';
import 'group_providers.dart';
import 'member_link_providers.dart';

final memberRoleRepositoryProvider = Provider(
  (ref) => MemberRoleRepository(
    FirestoreMemberRoleService(ref.watch(firestoreProvider)),
  ),
);
final nextMemberRoleProvider = Provider.autoDispose
    .family<GroupRole?, (String, GroupMember)>((ref, key) {
      if (!ref.watch(canEditGroupProvider(key.$1))) return null;
      return MemberRoleRepository.nextRole(
        key.$2,
        ref.watch(linkedPersonProvider(key)),
      );
    });
final canTransferOwnershipProvider = Provider.autoDispose.family<bool, String>(
  (ref, id) =>
      ref.watch(currentMembershipProvider(id))?.role == GroupRole.owner &&
      ref.watch(canEditGroupProvider(id)),
);
final ownershipCandidatesProvider = Provider.autoDispose
    .family<List<GroupMember>, String>((ref, id) {
      final owner = ref.watch(currentMembershipProvider(id));
      if (owner == null) return const [];
      final persons =
          ref.watch(personsProvider(id)).asData?.value ?? const <Person>[];
      final members =
          ref.watch(groupMembersProvider(id)).asData?.value ??
          const <GroupMember>[];
      return members
          .where((member) {
            Person? person;
            for (final row in persons) {
              if (row.id == member.personId) person = row;
            }
            return MemberRoleRepository.canReceiveOwnership(
              owner,
              member,
              person,
            );
          })
          .toList(growable: false);
    });

final memberRoleControllerProvider = NotifierProvider.autoDispose
    .family<MemberRoleController, AsyncValue<void>, String>(
      MemberRoleController.new,
    );

class MemberRoleController extends Notifier<AsyncValue<void>> {
  MemberRoleController(this.groupId);
  final String groupId;
  @override
  AsyncValue<void> build() => const AsyncData(null);
  String? validateConfirmation(String expected, String? value) =>
      MemberRoleRepository.confirmationError(expected, value);
  static const _denied = AppFailure(
    FailureCode.permissionDenied,
    'Los permisos o la sesión han cambiado. Actualiza los miembros.',
  );
  bool _sameSession(String uid) =>
      ref.mounted && ref.read(authStateProvider).asData?.value?.uid == uid;
  Future<bool> changeRole(GroupMember target, GroupRole next) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final actor = ref.read(authStateProvider).asData?.value?.uid;
      if (actor == null ||
          target.groupId != groupId ||
          ref.read(nextMemberRoleProvider((groupId, target))) != next) {
        throw _denied;
      }
      await ref
          .read(memberRoleRepositoryProvider)
          .changeRole(
            groupId,
            actor,
            target,
            ref.read(linkedPersonProvider((groupId, target))),
            next,
          );
      if (!_sameSession(actor)) return false;
      state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return false;
    }
  }

  Future<bool> transfer(
    Group group,
    GroupMember target,
    String confirmation,
  ) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final actor = ref.read(authStateProvider).asData?.value?.uid;
      final owner = ref.read(currentMembershipProvider(groupId));
      if (actor == null ||
          owner == null ||
          owner.uid != actor ||
          group.id != groupId ||
          !ref.read(canTransferOwnershipProvider(groupId)) ||
          validateConfirmation(group.name, confirmation) != null ||
          !ref
              .read(ownershipCandidatesProvider(groupId))
              .any((m) => m.uid == target.uid)) {
        throw _denied;
      }
      final auth = ref.read(authRepositoryProvider);
      final repository = ref.read(memberRoleRepositoryProvider);
      await auth.reauthenticateWithGoogle(actor);
      if (!_sameSession(actor)) throw _denied;
      if (!ref.read(canTransferOwnershipProvider(groupId))) throw _denied;
      // Check the current projections again after the Google interaction.
      final latestGroup = ref.read(groupProvider(groupId)).asData?.value;
      final latestOwner = ref.read(currentMembershipProvider(groupId));
      final candidates = ref.read(ownershipCandidatesProvider(groupId));
      GroupMember? latestTarget;
      for (final member in candidates) {
        if (member.uid == target.uid) latestTarget = member;
      }
      if (latestGroup?.updatedAt != group.updatedAt ||
          latestOwner?.updatedAt != owner.updatedAt ||
          latestTarget?.updatedAt != target.updatedAt) {
        throw _denied;
      }
      await repository.transfer(
        group,
        owner,
        target,
        ref.read(linkedPersonProvider((groupId, target))),
        confirmation,
      );
      if (!_sameSession(actor)) return false;
      state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return false;
    }
  }
}
