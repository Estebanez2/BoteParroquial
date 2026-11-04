import '../core/errors/app_failure.dart';
import '../core/routing/invitation_links.dart';
import '../models/export_file.dart';
import '../models/group_invitation.dart';
import '../models/photo_target.dart';
import '../services/group_invitation_service.dart';
import '../services/invitation_sharing_service.dart';
import '../services/photo_service.dart';

class InvitationShareRepository {
  InvitationShareRepository(this._invitations, this._photos, this._sharing);
  final GroupInvitationService _invitations;
  final PhotoService _photos;
  final InvitationSharingService _sharing;

  Future<void> share(
    String uid,
    InvitationSettings settings,
    bool Function() isCurrent,
  ) async {
    void check() {
      if (!settings.enabled || !isCurrent()) {
        throw const AppFailure(
          FailureCode.permissionDenied,
          'La invitación o tu acceso han cambiado. Vuelve a intentarlo.',
        );
      }
    }

    check();
    // Remote reads deliberately avoid exporting a stale private cached image.
    final target = PhotoTarget.group(settings.code.groupId);
    final access = await _photos.access(uid, target);
    check();
    if (!access.canRead) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'Ya no tienes acceso a la imagen de este grupo.',
      );
    }
    final photo = await _photos.read(uid, target);
    final bytes = photo ?? await _sharing.loadAppLogo();
    final preview = await _invitations.preview(settings.code, uid);
    check();
    final png = bytes.length >= 4 && bytes[0] == 137 && bytes[1] == 80;
    final webp = bytes.length >= 12 && bytes[8] == 87 && bytes[9] == 69;
    final extension = png ? 'png' : (webp ? 'webp' : 'jpg');
    await _sharing.shareInvitation(
      uid,
      ExportFile(
        name: 'bote-parroquial-invitacion.$extension',
        mimeType: 'image/${png ? 'png' : (webp ? 'webp' : 'jpeg')}',
        bytes: bytes,
      ),
      'Te invito a «${preview.groupName}» en BoteParroquial. '
      '¡Únete a nuestro grupo!\n\n'
      '${InvitationLinks.forCode(settings.code)}\n'
      'Código: ${settings.code.value}',
      isCurrent,
    );
  }
}
