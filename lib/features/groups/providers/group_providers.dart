import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../models/group.dart';
import '../../../models/group_member.dart';
import '../../../repositories/group_repository.dart';
import '../../../services/firestore_group_service.dart';
import '../../auth/providers/auth_providers.dart';

final groupRepositoryProvider = Provider<GroupRepository>(
  (ref) => DefaultGroupRepository(
    FirestoreGroupService(ref.watch(firestoreProvider)),
  ),
);

final membershipsProvider = StreamProvider.autoDispose<List<GroupMember>>((
  ref,
) async* {
  final user = await ref.watch(authStateProvider.future);
  if (!ref.mounted) return;
  if (user == null) {
    yield const [];
    return;
  }
  yield* ref.watch(groupRepositoryProvider).watchMemberships(user.uid);
}, retry: (_, _) => null);

// The route supplies groupId. Access is re-evaluated on account or membership changes.
final groupProvider = StreamProvider.autoDispose.family<Group?, String>((
  ref,
  groupId,
) async* {
  final memberships = await ref.watch(membershipsProvider.future);
  if (!ref.mounted) return;
  if (!memberships.any((m) => m.groupId == groupId && m.isActive)) {
    yield null;
    return;
  }
  yield* ref
      .watch(groupRepositoryProvider)
      .watchGroup(groupId)
      .map((group) => group?.isActive == true ? group : null);
}, retry: (_, _) => null);

final groupMembersProvider = StreamProvider.autoDispose
    .family<List<GroupMember>, String>((ref, groupId) async* {
      final group = await ref.watch(groupProvider(groupId).future);
      if (!ref.mounted) return;
      if (group == null) {
        yield const [];
        return;
      }
      yield* ref.watch(groupRepositoryProvider).watchMembers(groupId);
    }, retry: (_, _) => null);

final currentMembershipProvider = Provider.autoDispose
    .family<GroupMember?, String>((ref, groupId) {
      final state = ref.watch(membershipsProvider);
      if (state.isLoading || state.hasError) return null;
      for (final member in state.asData?.value ?? <GroupMember>[]) {
        if (member.groupId == groupId && member.isActive) return member;
      }
      return null;
    });
