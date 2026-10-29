import 'dart:convert';
import 'dart:math';
import '../core/errors/app_failure.dart';
import '../core/routing/invitation_links.dart';
import '../models/group_invitation.dart';
import '../models/group_member.dart';
import '../services/group_invitation_service.dart';
import '../services/file_sharing_service.dart';

class GroupInvitationRepository {
  GroupInvitationRepository(this._service, this._sharing);
  final GroupInvitationService _service;
  final FileSharingService _sharing;
  String newSecret() {
    final random = Random.secure();
    return base64UrlEncode(List.generate(24, (_) => random.nextInt(256)));
  }

  InvitationCode parse(String text) {
    final code = InvitationLinks.parse(text);
    if (code == null) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Pega un código completo de BoteParroquial.',
      );
    }
    return code;
  }

  Stream<InvitationSettings?> watchSettings(String groupId) =>
      _service.watchSettings(groupId);
  Stream<List<GroupJoinRequest>> watchRequests(String groupId) =>
      _service.watchRequests(groupId);
  Future<InvitationPreview> preview(String text, String uid) =>
      _service.preview(parse(text), uid);
  Future<void> configure(
    String groupId,
    String uid, {
    required bool enabled,
    required bool requiresApproval,
    InvitationSettings? original,
    bool regenerate = false,
  }) {
    if (original != null && original.code.groupId != groupId) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'La invitación pertenece a otro grupo.',
      );
    }
    return _service.configure(
      groupId,
      uid,
      newCode: regenerate || original == null
          ? newSecret()
          : original.code.secret,
      enabled: enabled,
      requiresApproval: requiresApproval,
      original: original,
    );
  }

  Future<JoinRequestStatus> submit(
    InvitationPreview preview,
    String uid,
    String name,
  ) {
    if (name.trim().isEmpty || name.trim().length > 256) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Tu perfil necesita un nombre válido.',
      );
    }
    return _service.submit(preview, uid, name.trim());
  }

  Future<void> decide(
    String groupId,
    String uid,
    GroupJoinRequest request,
    bool approve,
  ) => _service.decide(groupId, uid, request, approve);
  Future<void> remove(String groupId, String uid, GroupMember target) {
    if (target.groupId != groupId ||
        target.role == GroupRole.owner ||
        !target.isActive) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'No se puede retirar el acceso de esta membresía. El propietario debe transferir antes su propiedad.',
      );
    }
    return _service.remove(groupId, uid, target);
  }

  Future<void> copy(InvitationSettings settings) async {
    if (!settings.enabled) {
      throw const AppFailure(
        FailureCode.invalidData,
        'La invitación está desactivada.',
      );
    }
    await _sharing.copyText(settings.code.value);
  }

  Future<void> share(InvitationSettings settings) async {
    if (!settings.enabled) {
      throw const AppFailure(
        FailureCode.invalidData,
        'La invitación está desactivada.',
      );
    }
    await _sharing.shareText(InvitationLinks.forCode(settings.code).toString());
  }

  Future<void> copyLink(InvitationSettings settings) async {
    if (!settings.enabled) {
      throw const AppFailure(
        FailureCode.invalidData,
        'La invitación está desactivada.',
      );
    }
    await _sharing.copyText(InvitationLinks.forCode(settings.code).toString());
  }
}
