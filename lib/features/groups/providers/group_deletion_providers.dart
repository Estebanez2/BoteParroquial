import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../models/group_deletion.dart';
import '../../../repositories/group_deletion_repository.dart';
import '../../../services/firestore_group_deletion_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../models/group_member.dart';
import 'group_providers.dart';

final canDeleteGroupProvider = Provider.autoDispose.family<bool, String>(
  (ref, id) =>
      ref.watch(currentMembershipProvider(id))?.role == GroupRole.owner &&
      ref.watch(groupProvider(id)).asData?.value?.isActive == true,
);

final groupDeletionRepositoryProvider = Provider(
  (ref) => GroupDeletionRepository(
    FirestoreGroupDeletionService(
      ref.watch(firestoreProvider),
      ref.watch(supabaseConnectionProvider),
    ),
    ref.watch(authRepositoryProvider),
  ),
);
final groupDeletionPreviewProvider = FutureProvider.autoDispose
    .family<GroupDeletionPreview, String>((ref, id) {
      final uid = ref.watch(authStateProvider).asData?.value?.uid;
      if (uid == null) {
        throw const AppFailure(FailureCode.permissionDenied, 'Inicia sesión.');
      }
      return ref.watch(groupDeletionRepositoryProvider).preview(id, uid);
    }, retry: (_, _) => null);
final pendingGroupDeletionsProvider =
    StreamProvider.autoDispose<List<GroupDeletionTask>>((ref) {
      final uid = ref.watch(authStateProvider).asData?.value?.uid;
      return uid == null
          ? Stream.value(const [])
          : ref.watch(groupDeletionRepositoryProvider).watchPending(uid);
    }, retry: (_, _) => null);
final groupDeletionControllerProvider = NotifierProvider.autoDispose
    .family<GroupDeletionController, AsyncValue<bool?>, String>(
      GroupDeletionController.new,
    );

class GroupDeletionController extends Notifier<AsyncValue<bool?>> {
  GroupDeletionController(this.groupId);
  final String groupId;
  @override
  AsyncValue<bool?> build() => const AsyncData(null);
  Future<bool?> remove(String expectedName, String typedName) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    try {
      final uid = ref.read(authStateProvider).asData?.value?.uid;
      if (uid == null) {
        throw const AppFailure(FailureCode.permissionDenied, 'Inicia sesión.');
      }
      final result = await ref
          .read(groupDeletionRepositoryProvider)
          .remove(groupId, uid, expectedName, typedName);
      if (!ref.mounted) return null;
      if (ref.read(authStateProvider).asData?.value?.uid != uid) {
        throw const AppFailure(FailureCode.cancelled, 'La sesión ha cambiado.');
      }
      state = AsyncData(result);
      return result;
    } catch (e, s) {
      if (ref.mounted) state = AsyncError(e, s);
      return null;
    }
  }
}
