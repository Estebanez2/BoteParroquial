import 'custom_palette.dart';

// Persisted IDs: visible names are defined in AppPaletteCatalog.
enum AppPalette { atlantic, iris, coral, forest, graphite }

enum AppearanceMode { system, light, dark }

enum AppFont { manrope, newsreader, system }

class AppearanceSettings {
  const AppearanceSettings({
    this.palette = AppPalette.atlantic,
    this.mode = AppearanceMode.system,
    this.font = AppFont.manrope,
    this.customPalettes = const [],
    this.customPaletteId,
  });
  final AppPalette palette;
  final AppearanceMode mode;
  final AppFont font;
  final List<CustomPalette> customPalettes;
  final String? customPaletteId;
  CustomPalette? get customPalette => customPalettes
      .where((p) => p.id == customPaletteId && p.isValid)
      .firstOrNull;
  AppearanceSettings copyWith({
    AppPalette? palette,
    AppearanceMode? mode,
    AppFont? font,
    List<CustomPalette>? customPalettes,
    String? customPaletteId,
    bool clearCustom = false,
  }) => AppearanceSettings(
    palette: palette ?? this.palette,
    mode: mode ?? this.mode,
    font: font ?? this.font,
    customPalettes: customPalettes ?? this.customPalettes,
    customPaletteId: clearCustom
        ? null
        : customPaletteId ?? this.customPaletteId,
  );
  Map<String, Object?> toJson() => {
    'version': 2,
    'palette': palette.name,
    'mode': mode.name,
    'font': font.name,
    'customPalettes': customPalettes.map((p) => p.toJson()).toList(),
    'customPaletteId': customPaletteId,
  };
  factory AppearanceSettings.fromJson(
    Map<String, Object?> json,
  ) => AppearanceSettings(
    customPalettes: List.unmodifiable(_palettes(json['customPalettes'])),
    customPaletteId: json['customPaletteId'] is String
        ? json['customPaletteId'] as String
        : null,
    font:
        AppFont.values.where((font) => font.name == json['font']).firstOrNull ??
        AppFont.manrope,
    palette:
        AppPalette.values.where((p) => p.name == json['palette']).firstOrNull ??
        AppPalette.atlantic,
    mode:
        AppearanceMode.values
            .where((m) => m.name == json['mode'])
            .firstOrNull ??
        AppearanceMode.system,
  );

  static List<CustomPalette> _palettes(Object? value) {
    if (value is! List) return const [];
    final ids = <String>{};
    return [
      for (final raw in value)
        if (CustomPalette.parse(raw) case final CustomPalette p)
          if (ids.add(p.id)) p,
    ];
  }
}
