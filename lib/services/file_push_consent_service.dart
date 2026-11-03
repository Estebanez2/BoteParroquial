import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../core/errors/app_failure.dart';
import 'notification_service.dart';

/// Stores only a boolean decision, never tokens or credentials.
final class FilePushConsentService implements PushConsentService {
  FilePushConsentService({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _directory;
  Future<File> _file(String uid) async {
    final root = await _directory();
    await root.create(recursive: true);
    final hash = sha256.convert(utf8.encode(uid));
    return File('${root.path}/push_consent_$hash.json');
  }

  static const _failure = AppFailure(
    FailureCode.configuration,
    'No se pudo guardar tu elección de avisos. Puedes revisarla en Tu perfil.',
  );
  @override
  Future<bool?> read(String uid) async {
    try {
      final file = await _file(uid);
      if (!await file.exists()) return null;
      final data = jsonDecode(await file.readAsString());
      if (data is! Map || data['version'] != 1 || data['enabled'] is! bool) {
        throw _failure;
      }
      return data['enabled'] as bool;
    } catch (_) {
      throw _failure;
    }
  }

  @override
  Future<void> write(String uid, bool enabled) async {
    try {
      final file = await _file(uid);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
        jsonEncode({'version': 1, 'enabled': enabled}),
        flush: true,
      );
      await temporary.rename(file.path);
    } catch (_) {
      throw _failure;
    }
  }
}
