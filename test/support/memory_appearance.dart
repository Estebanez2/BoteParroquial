import 'package:bote_parroquial/models/appearance_settings.dart';
import 'package:bote_parroquial/services/appearance_service.dart';

class MemoryAppearance implements AppearanceService {
  AppearanceSettings? saved;
  bool failSave = false;
  @override
  Future<AppearanceSettings?> load() async => saved;
  @override
  Future<void> save(AppearanceSettings settings) async {
    if (failSave) throw StateError('Storage unavailable');
    saved = settings;
  }
}
