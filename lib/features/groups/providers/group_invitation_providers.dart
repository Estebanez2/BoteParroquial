import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../models/group_invitation.dart';
import '../../../models/group_member.dart';
import '../../../repositories/group_invitation_repository.dart';
import '../../../services/firestore_group_invitation_service.dart';
import '../../../services/native_file_sharing_service.dart';
import '../../auth/providers/auth_providers.dart';
import 'group_management_providers.dart';
import 'group_providers.dart';

final groupInvitationRepositoryProvider = Provider(
  (ref) => GroupInvitationRepository(
    FirestoreGroupInvitationService(ref.watch(firestoreProvider)),
    NativeFileSharingService(),
  ),
);
final invitationSettingsProvider = StreamProvider.autoDispose
    .family<InvitationSettings?, String>((ref, id) {
      if (ref.watch(currentMembershipProvider(id)) == null) {
        return Stream.value(null);
      }
      return ref.watch(groupInvitationRepositoryProvider).watchSettings(id);
    }, retry: (_, _) => null);
final groupJoinRequestsProvider = StreamProvider.autoDispose
    .family<List<GroupJoinRequest>, String>((ref, id) {
      if (!ref.watch(canEditGroupProvider(id))) return Stream.value(const []);
      return ref.watch(groupInvitationRepositoryProvider).watchRequests(id);
    }, retry: (_, _) => null);
final canRemoveMemberProvider = Provider.autoDispose
    .family<bool, (String, GroupMember)>((ref, key) {
      final current = ref.watch(currentMembershipProvider(key.$1)),
          target = key.$2;
      return current != null &&
          target.isActive &&
          target.role != GroupRole.owner &&
          target.groupId == key.$1 &&
          (current.uid == target.uid ||
              ref.watch(canEditGroupProvider(key.$1)));
    });
final invitationControllerProvider = NotifierProvider.autoDispose
    .family<InvitationController, AsyncValue<void>, String>(
      InvitationController.new,
    );

class InvitationController extends Notifier<AsyncValue<void>> {
  InvitationController(this.groupId);
  final String groupId;
  @override
  AsyncValue<void> build() => const AsyncData(null);
  Future<bool> _perform(
    Future<void> Function(GroupInvitationRepository, String) action, {
    bool manage = true,
  }) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final uid = ref.read(authStateProvider).asData?.value?.uid;
      if (uid == null ||
          ref.read(currentMembershipProvider(groupId)) == null ||
          (manage && !ref.read(canEditGroupProvider(groupId)))) {
        throw const AppFailure(
          FailureCode.permissionDenied,
          'Ya no tienes permiso para esta operación.',
        );
      }
      await action(ref.read(groupInvitationRepositoryProvider), uid);
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return false;
    }
  }

  Future<bool> configure({
    required bool enabled,
    required bool requiresApproval,
    InvitationSettings? original,
    bool regenerate = false,
  }) => _perform(
    (repo, uid) => repo.configure(
      groupId,
      uid,
      enabled: enabled,
      requiresApproval: requiresApproval,
      original: original,
      regenerate: regenerate,
    ),
  );
  Future<bool> decide(GroupJoinRequest request, bool approve) =>
      _perform((repo, uid) => repo.decide(groupId, uid, request, approve));
  Future<bool> remove(GroupMember target) => _perform((repo, uid) {
    if (!ref.read(canRemoveMemberProvider((groupId, target)))) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'No puedes retirar este acceso.',
      );
    }
    return repo.remove(groupId, uid, target);
  }, manage: false);
  Future<bool> copy(InvitationSettings settings) =>
      _perform((repo, _) => repo.copy(settings), manage: false);
  Future<bool> copyLink(InvitationSettings settings) =>
      _perform((repo, _) => repo.copyLink(settings), manage: false);
  Future<bool> share(InvitationSettings settings) =>
      _perform((repo, _) => repo.share(settings), manage: false);
}

class JoinState {
  const JoinState({
    this.preview,
    this.result,
    this.loading = false,
    this.error,
  });
  final InvitationPreview? preview;
  final JoinRequestStatus? result;
  final bool loading;
  final Object? error;
}

final joinGroupProvider =
    NotifierProvider.autoDispose<JoinGroupController, JoinState>(
      JoinGroupController.new,
    );

class JoinGroupController extends Notifier<JoinState> {
  @override
  JoinState build() {
    ref.watch(authStateProvider.select((v) => v.asData?.value?.uid));
    return const JoinState();
  }

  void clear() {
    if (!state.loading) state = const JoinState();
  }

  Future<void> preview(String code) async {
    if (state.loading) return;
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    state = const JoinState(loading: true);
    try {
      if (uid == null) {
        throw const AppFailure(
          FailureCode.permissionDenied,
          'Inicia sesión para consultar una invitación.',
        );
      }
      final preview = await ref
          .read(groupInvitationRepositoryProvider)
          .preview(code, uid);
      if (ref.mounted &&
          ref.read(authStateProvider).asData?.value?.uid == uid) {
        state = JoinState(preview: preview);
      }
    } catch (error) {
      if (ref.mounted &&
          ref.read(authStateProvider).asData?.value?.uid == uid) {
        state = JoinState(error: error);
      }
    }
  }

  Future<void> submit() async {
    final preview = state.preview;
    if (state.loading || preview == null) return;
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    state = JoinState(preview: preview, loading: true);
    try {
      if (uid == null) {
        throw const AppFailure(
          FailureCode.permissionDenied,
          'Inicia sesión para solicitar entrada.',
        );
      }
      final repo = ref.read(groupInvitationRepositoryProvider);
      final profile = await ref.read(userProfileProvider.future);
      if (!ref.mounted ||
          ref.read(authStateProvider).asData?.value?.uid != uid) {
        return;
      }
      if (profile?.uid != uid) {
        throw const AppFailure(
          FailureCode.invalidData,
          'No pudimos preparar tu perfil. Vuelve a tus grupos y reintenta.',
        );
      }
      final result = await repo.submit(preview, uid, profile!.displayName);
      if (ref.mounted &&
          ref.read(authStateProvider).asData?.value?.uid == uid) {
        state = JoinState(preview: preview, result: result);
      }
    } catch (error) {
      if (ref.mounted &&
          ref.read(authStateProvider).asData?.value?.uid == uid) {
        state = JoinState(preview: preview, error: error);
      }
    }
  }
}
