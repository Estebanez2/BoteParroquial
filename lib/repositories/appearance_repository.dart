import '../models/appearance_settings.dart';
import '../models/custom_palette.dart';
import '../services/appearance_service.dart';

class AppearanceRepository {
  const AppearanceRepository(this.service);
  final AppearanceService service;
  Future<AppearanceSettings> load() async {
    try {
      return await service.load() ?? const AppearanceSettings();
    } catch (_) {
      return const AppearanceSettings();
    }
  }

  Future<void> save(AppearanceSettings settings) => service.save(settings);
  String newPaletteId() => 'local-${DateTime.now().microsecondsSinceEpoch}';
  AppearanceSettings withPalette(
    AppearanceSettings settings,
    CustomPalette palette,
  ) {
    if (!palette.isValid) {
      throw const FormatException(
        'Escribe un nombre de 1 a 40 caracteres y tres colores válidos.',
      );
    }
    return settings.copyWith(
      customPalettes: List.unmodifiable([
        for (final old in settings.customPalettes)
          if (old.id != palette.id) old,
        palette,
      ]),
      customPaletteId: palette.id,
    );
  }

  AppearanceSettings withoutPalette(AppearanceSettings settings, String id) =>
      settings.copyWith(
        customPalettes: List.unmodifiable(
          settings.customPalettes.where((p) => p.id != id),
        ),
        clearCustom: settings.customPaletteId == id,
      );
}
