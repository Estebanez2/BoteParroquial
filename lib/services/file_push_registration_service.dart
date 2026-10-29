import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/errors/app_failure.dart';
import '../models/group_notification.dart';
import 'notification_service.dart';

final class FilePushRegistrationService implements PushRegistrationService {
  FilePushRegistrationService({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _directory;
  static const _failure = AppFailure(
    FailureCode.configuration,
    'No pudimos comprobar los avisos de este móvil. Reintenta antes de cambiar de cuenta.',
  );
  Future<File> _file() async {
    final root = await _directory();
    await root.create(recursive: true);
    return File('${root.path}/push_registration.json');
  }

  @override
  Future<PushRegistration?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final value = jsonDecode(await file.readAsString());
      if (value is! Map ||
          value['version'] != 1 ||
          value['uid'] is! String ||
          (value['uid'] as String).isEmpty ||
          value['tokenIds'] is! List) {
        throw _failure;
      }
      final ids = (value['tokenIds'] as List).cast<String>();
      if (ids.isEmpty ||
          ids.any((id) => !RegExp(r'^[a-f0-9]{64}$').hasMatch(id))) {
        throw _failure;
      }
      if (value['enabled'] != null && value['enabled'] is! bool) {
        throw _failure;
      }
      return PushRegistration(
        uid: value['uid'] as String,
        tokenIds: ids,
        enabled: value['enabled'] != false,
      );
    } catch (_) {
      throw _failure;
    }
  }

  @override
  Future<void> write(PushRegistration registration) async {
    try {
      final file = await _file();
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
        jsonEncode({
          'version': 1,
          'uid': registration.uid,
          'tokenIds': registration.tokenIds,
          'enabled': registration.enabled,
        }),
        flush: true,
      );
      await temporary.rename(file.path);
    } catch (_) {
      throw _failure;
    }
  }

  @override
  Future<void> clear() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (_) {
      throw _failure;
    }
  }
}
