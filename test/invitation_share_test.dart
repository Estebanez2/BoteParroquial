import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/models/export_file.dart';
import 'package:bote_parroquial/models/group_invitation.dart';
import 'package:bote_parroquial/models/photo_target.dart';
import 'package:bote_parroquial/repositories/invitation_share_repository.dart';
import 'package:bote_parroquial/services/group_invitation_service.dart';
import 'package:bote_parroquial/services/invitation_sharing_service.dart';
import 'package:bote_parroquial/services/photo_service.dart';

class Invitations extends Fake implements GroupInvitationService {
  @override
  Future<InvitationPreview> preview(InvitationCode code, String uid) async =>
      InvitationPreview(
        code: code,
        groupName: 'Catequesis',
        currency: 'EUR',
        requiresApproval: true,
      );
}

class Photos extends Fake implements PhotoService {
  Uint8List? image;
  bool allowed = true;
  void Function()? onRead;
  @override
  Future<PhotoAccess> access(String actorUid, PhotoTarget target) async =>
      PhotoAccess(canRead: allowed, canEdit: false);
  @override
  Future<Uint8List?> read(String actorUid, PhotoTarget target) async {
    onRead?.call();
    return image;
  }
}

class Sharing implements InvitationSharingService {
  int logoLoads = 0;
  ExportFile? attachment;
  String? caption;
  @override
  Future<Uint8List> loadAppLogo() async {
    logoLoads++;
    return Uint8List.fromList([137, 80, 78, 71]);
  }

  @override
  Future<void> shareInvitation(
    String uid,
    ExportFile image,
    String text,
    bool Function() isCurrent,
  ) async {
    if (!isCurrent()) throw StateError('stale');
    attachment = image;
    caption = text;
  }
}

void main() {
  late Photos photos;
  late Sharing sharing;
  late InvitationShareRepository repository;
  final settings = InvitationSettings(
    code: InvitationCode(groupId: 'catequesis', secret: 'a' * 32),
    enabled: true,
    requiresApproval: true,
    updatedAt: DateTime.utc(2026),
  );
  setUp(() {
    photos = Photos();
    sharing = Sharing();
    repository = InvitationShareRepository(Invitations(), photos, sharing);
  });
  test(
    'Shares private group image with group name, invitation phrase and link',
    () async {
      photos.image = Uint8List.fromList([255, 216, 255, 224]);
      await repository.share('owner', settings, () => true);
      expect(sharing.attachment!.bytes, photos.image);
      expect(sharing.attachment!.mimeType, 'image/jpeg');
      expect(sharing.logoLoads, 0);
      expect(sharing.caption, contains('Te invito a «Catequesis»'));
      expect(sharing.caption, contains('https://boteparroquial.web.app/join/'));
      expect(sharing.caption, contains(settings.code.value));
    },
  );
  test('No group image uses bundled app logo as PNG', () async {
    await repository.share('owner', settings, () => true);
    expect(sharing.logoLoads, 1);
    expect(sharing.attachment!.mimeType, 'image/png');
  });
  test('Denied access and session changes never open native share', () async {
    photos.allowed = false;
    await expectLater(
      repository.share('owner', settings, () => true),
      throwsA(isA<AppFailure>()),
    );
    expect(sharing.attachment, isNull);
    photos.allowed = true;
    var current = true;
    photos.onRead = () => current = false;
    await expectLater(
      repository.share('owner', settings, () => current),
      throwsA(isA<AppFailure>()),
    );
    expect(sharing.attachment, isNull);
  });
}
