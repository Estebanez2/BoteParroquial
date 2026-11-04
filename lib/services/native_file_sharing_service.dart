import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/errors/app_failure.dart';
import '../models/export_file.dart';
import 'file_sharing_service.dart';
import 'invitation_sharing_service.dart';

class NativeFileSharingService
    implements FileSharingService, InvitationSharingService {
  @override
  Future<Uint8List> loadAppLogo() async => (await rootBundle.load(
    'assets/branding/bote_parroquial.png',
  )).buffer.asUint8List();

  @override
  Future<void> shareInvitation(
    String uid,
    ExportFile image,
    String text,
    bool Function() isCurrent,
  ) async {
    await _share(uid, image, text: text, isCurrent: isCurrent);
  }

  @override
  Future<void> copyText(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } on PlatformException {
      throw const AppFailure(
        FailureCode.unknown,
        'No se pudo copiar el código.',
      );
    }
  }

  @override
  Future<void> shareText(String text) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: text, title: 'Invitación de BoteParroquial'),
      );
    } on PlatformException {
      throw const AppFailure(
        FailureCode.unknown,
        'No se pudo compartir el código.',
      );
    }
  }

  final _generation = <String, int>{};
  Future<Directory> _folder(String uid) async {
    final root = await getTemporaryDirectory();
    return Directory(
      '${root.path}/bote_csv_exports/${sha256.convert(utf8.encode(uid))}',
    );
  }

  @override
  Future<FileShareOutcome> share(String uid, ExportFile file) =>
      _share(uid, file);

  Future<FileShareOutcome> _share(
    String uid,
    ExportFile file, {
    String? text,
    bool Function()? isCurrent,
  }) async {
    final generation = _generation[uid] ?? 0;
    try {
      final folder = await _folder(uid);
      await folder.create(recursive: true);
      final directories = await folder
          .list(followLinks: false)
          .where((entry) => entry is Directory)
          .cast<Directory>()
          .toList();
      final dated = <(Directory, DateTime)>[];
      for (final directory in directories) {
        dated.add((directory, (await directory.stat()).modified));
      }
      dated.sort((a, b) => b.$2.compareTo(a.$2));
      for (var i = 0; i < dated.length; i++) {
        if (i >= 9 ||
            DateTime.now().difference(dated[i].$2) > const Duration(days: 1)) {
          await dated[i].$1.delete(recursive: true);
        }
      }
      final request = await folder.createTemp('share_');
      final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
      final target = File('${request.path}/$safeName');
      await target.writeAsBytes(file.bytes, flush: true);
      if ((_generation[uid] ?? 0) != generation ||
          (isCurrent != null && !isCurrent())) {
        await request.delete(recursive: true);
        throw const AppFailure(
          FailureCode.cancelled,
          'La sesión ha cambiado; la exportación se ha descartado.',
        );
      }
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(target.path, mimeType: file.mimeType)],
          text: text,
          title: text == null
              ? 'Exportar movimientos'
              : 'Invitación de BoteParroquial',
          subject: text == null
              ? 'BoteParroquial · Movimientos'
              : 'BoteParroquial · Invitación',
        ),
      );
      return switch (result.status) {
        ShareResultStatus.success => FileShareOutcome.shared,
        ShareResultStatus.dismissed => FileShareOutcome.cancelled,
        _ => FileShareOutcome.unknown,
      };
    } on FileSystemException {
      throw const AppFailure(
        FailureCode.unknown,
        'No se pudo preparar el archivo de exportación.',
      );
    } on PlatformException {
      throw const AppFailure(
        FailureCode.unknown,
        'No se pudo abrir el menú para compartir el archivo.',
      );
    }
  }

  @override
  Future<void> clearAccount(String uid) async {
    _generation[uid] = (_generation[uid] ?? 0) + 1;
    try {
      final directory = await _folder(uid);
      if (await directory.exists()) await directory.delete(recursive: true);
    } on FileSystemException {
      /* Private temporary data can be evicted by the OS. */
    }
  }
}
