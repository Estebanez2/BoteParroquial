import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../repositories/group_sync_repository.dart';
import '../../../services/group_sync_service.dart';
import '../../auth/providers/auth_providers.dart';
import 'group_providers.dart';

final groupSyncRepositoryProvider = Provider<GroupSyncRepository>(
  (ref) => GroupSyncRepository(
    FirestoreGroupSyncService(ref.watch(firestoreProvider)),
  ),
);
final groupServerConfirmedProvider = StreamProvider.autoDispose
    .family<bool, String>((ref, groupId) {
      final user = ref.watch(authStateProvider).asData?.value;
      final member = ref.watch(currentMembershipProvider(groupId));
      if (user == null || member == null) return Stream.value(false);
      return ref
          .watch(groupSyncRepositoryProvider)
          .watchServerConfirmation(groupId, user.uid);
    }, retry: (_, _) => null);
