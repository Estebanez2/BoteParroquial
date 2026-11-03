import '../../models/appearance_settings.dart';

/// Visible identities. Enum names remain stable for existing local preferences.
abstract final class AppPaletteCatalog {
  static String label(AppPalette palette) => switch (palette) {
    AppPalette.atlantic => 'Atlántico',
    AppPalette.iris => 'Cyberpunk',
    AppPalette.coral => 'Cartoon',
    AppPalette.forest => 'Arcade',
    AppPalette.graphite => 'Pop Art',
  };
  static String description(AppPalette palette) => switch (palette) {
    AppPalette.atlantic => 'Azul, ámbar y lavanda · Contraste sereno',
    AppPalette.iris => 'Amarillo ácido, cian y fucsia · Neón sobre violeta',
    AppPalette.coral => 'Azul eléctrico, rojo y amarillo · Viñetas de color',
    AppPalette.forest =>
      'Verde radiactivo, uva y naranja · Energía de recreativa',
    AppPalette.graphite => 'Mandarina, violeta y lima · Contraste explosivo',
  };
}
