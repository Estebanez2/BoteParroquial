import '../models/appearance_settings.dart';

abstract interface class AppearanceService {
  Future<AppearanceSettings?> load();
  Future<void> save(AppearanceSettings settings);
}
