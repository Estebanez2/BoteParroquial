import '../models/group_invitation.dart';
import '../models/group_member.dart';

abstract interface class GroupInvitationService {
  Stream<InvitationSettings?> watchSettings(String groupId);
  Stream<List<GroupJoinRequest>> watchRequests(String groupId);
  Future<InvitationPreview> preview(InvitationCode code, String uid);
  Future<void> configure(
    String groupId,
    String uid, {
    required String newCode,
    required bool enabled,
    required bool requiresApproval,
    InvitationSettings? original,
  });
  Future<JoinRequestStatus> submit(
    InvitationPreview preview,
    String uid,
    String displayName,
  );
  Future<void> decide(
    String groupId,
    String uid,
    GroupJoinRequest request,
    bool approve,
  );
  Future<void> remove(String groupId, String uid, GroupMember target);
}
