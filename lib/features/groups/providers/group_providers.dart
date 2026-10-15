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
) {
  final session = ref.watch(authStateProvider);
  if (session.isLoading) return const Stream.empty();
  if (session.hasError) return Stream.error(session.error!, session.stackTrace);
  final user = session.asData?.value;
  if (user == null) {
    return Stream.value(const []);
  }
  return ref.watch(groupRepositoryProvider).watchMemberships(user.uid);
}, retry: (_, _) => null);

// The route supplies groupId. Access is re-evaluated on account or membership changes.
final groupProvider = StreamProvider.autoDispose.family<Group?, String>((
  ref,
  groupId,
) {
  final state = ref.watch(membershipsProvider);
  if (state.isLoading) return const Stream.empty();
  if (state.hasError) return Stream.error(state.error!, state.stackTrace);
  final memberships = state.asData?.value ?? <GroupMember>[];
  if (!memberships.any((m) => m.groupId == groupId && m.isActive)) {
    return Stream.value(null);
  }
  return ref
      .watch(groupRepositoryProvider)
      .watchGroup(groupId)
      .map((group) => group?.isActive == true ? group : null);
}, retry: (_, _) => null);

final groupMembersProvider = StreamProvider.autoDispose
    .family<List<GroupMember>, String>((ref, groupId) {
      final group = ref.watch(groupProvider(groupId));
      if (group.isLoading) return const Stream.empty();
      if (group.hasError) return Stream.error(group.error!, group.stackTrace);
      if (group.asData?.value == null) {
        return Stream.value(const []);
      }
      return ref.watch(groupRepositoryProvider).watchMembers(groupId);
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
