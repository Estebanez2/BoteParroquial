import 'dart:typed_data';
import '../models/export_file.dart';

abstract interface class InvitationSharingService {
  Future<Uint8List> loadAppLogo();
  Future<void> shareInvitation(
    String uid,
    ExportFile image,
    String text,
    bool Function() isCurrent,
  );
}
