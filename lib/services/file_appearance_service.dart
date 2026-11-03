import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/appearance_settings.dart';
import 'appearance_service.dart';

/// Device-wide presentation preferences, independent of any account or snapshot.
class FileAppearanceService implements AppearanceService {
  FileAppearanceService({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _directory;
  Future<void> _tail = Future.value();
  Future<File> _file() async {
    final directory = await _directory();
    await directory.create(recursive: true);
    return File('${directory.path}/appearance.json');
  }

  @override
  Future<AppearanceSettings?> load() async {
    final file = await _file();
    if (!await file.exists()) return null;
    final json = jsonDecode(await file.readAsString());
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid appearance settings');
    }
    return AppearanceSettings.fromJson(json.cast<String, Object?>());
  }

  @override
  Future<void> save(AppearanceSettings settings) {
    final operation = _tail.then((_) async {
      final file = await _file();
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(jsonEncode(settings.toJson()), flush: true);
      await temporary.rename(file.path);
    });
    _tail = operation.catchError((Object _) {});
    return operation;
  }
}
