import 'package:flutter/material.dart';
import '../../models/appearance_settings.dart';
import '../../models/custom_palette.dart';

/// Semantic palette. Always resolve from context so dark mode remains automatic.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.secondary,
    required this.secondaryContainer,
    this.tertiary = const Color(0xFF6850A1),
    this.tertiaryContainer = const Color(0xFFEDE6FA),
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.divider,
    required this.outline,
    required this.hero,
    required this.onHero,
  });
  final Color primary, primaryContainer, onPrimary;
  final Color secondary, secondaryContainer;
  final Color tertiary, tertiaryContainer;
  final Color background, surface, surfaceVariant;
  final Color textPrimary, textSecondary, textMuted;
  final Color success, warning, danger, info, divider, outline;
  final Color hero, onHero;
  Color get onImage => const Color(0xFFFFFFFF);
  Color get imageScrim => const Color(0xFF000000);

  static const light = AppColors(
    primary: Color(0xFF2459C4),
    primaryContainer: Color(0xFFE4ECFF),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF9A503A),
    secondaryContainer: Color(0xFFF5E6DE),
    background: Color(0xFFF4F6FA),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFEDF0F6),
    textPrimary: Color(0xFF202838),
    textSecondary: Color(0xFF505D73),
    textMuted: Color(0xFF636F82),
    success: Color(0xFF236749),
    warning: Color(0xFF88591A),
    danger: Color(0xFFB23E3E),
    info: Color(0xFF345F87),
    divider: Color(0xFFE1E6EF),
    outline: Color(0xFF7F8FA9),
    hero: Color(0xFFE4ECFF),
    onHero: Color(0xFF202838),
  );
  static const dark = AppColors(
    primary: Color(0xFFAAC5FF),
    primaryContainer: Color(0xFF243857),
    onPrimary: Color(0xFF14243E),
    secondary: Color(0xFFFFA899),
    secondaryContainer: Color(0xFF40292B),
    tertiary: Color(0xFFD0BCFF),
    tertiaryContainer: Color(0xFF352D50),
    background: Color(0xFF11151E),
    surface: Color(0xFF1C2230),
    surfaceVariant: Color(0xFF293243),
    textPrimary: Color(0xFFF2F5FC),
    textSecondary: Color(0xFFC2CCDC),
    textMuted: Color(0xFFA1AEC2),
    success: Color(0xFF7FE0B5),
    warning: Color(0xFFF2CC8F),
    danger: Color(0xFFFF8490),
    info: Color(0xFFA8BFF8),
    divider: Color(0xFF343E50),
    outline: Color(0xFF7386A6),
    hero: Color(0xFF243857),
    onHero: Color(0xFFF2F5FC),
  );

  static AppColors forPalette(AppPalette palette, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? dark : light;
    // Keep Atlantic byte-for-byte equivalent in every semantic token.
    if (palette == AppPalette.atlantic) {
      final accent = base.primary;
      return base.copyWith(
        secondary: isDark ? const Color(0xFFFFBD86) : const Color(0xFF98501C),
        secondaryContainer: isDark
            ? const Color(0xFF483321)
            : const Color(0xFFFFE9D3),
        tertiary: isDark ? const Color(0xFFD5BFFF) : const Color(0xFF6750A0),
        tertiaryContainer: isDark
            ? const Color(0xFF362D4D)
            : const Color(0xFFEFE7FF),
        hero: base.primaryContainer,
        surfaceVariant: Color.lerp(base.surface, accent, isDark ? .10 : .045),
        divider: Color.lerp(base.surface, base.textPrimary, isDark ? .12 : .10),
        outline: Color.lerp(accent, base.textPrimary, .35),
      );
    }
    final (
      primary,
      secondary,
      tertiary,
      background,
      surface,
    ) = switch (palette) {
      AppPalette.iris => (
        0xF4FF00,
        0x00F0FF,
        0xFF2AB5,
        isDark ? const Color(0xFF080510) : const Color(0xFFFAF3FF),
        isDark ? const Color(0xFF140B24) : const Color(0xFFFFFDFF),
      ),
      AppPalette.coral => (
        0x165CFF,
        0xF33556,
        0xFFCC00,
        isDark ? const Color(0xFF171D38) : const Color(0xFFFFF6DB),
        isDark ? const Color(0xFF242C4A) : const Color(0xFFFFFDF6),
      ),
      AppPalette.forest => (
        0x00FF85,
        0xA747FF,
        0xFF8A00,
        isDark ? const Color(0xFF06110B) : const Color(0xFFEBFFF5),
        isDark ? const Color(0xFF10221A) : const Color(0xFFF9FFFC),
      ),
      AppPalette.graphite => (
        0xFF4A00,
        0x6A00FF,
        0xC3FF00,
        isDark ? const Color(0xFF210C19) : const Color(0xFFFFF0EA),
        isDark ? const Color(0xFF351226) : const Color(0xFFFFFAF6),
      ),
      AppPalette.atlantic => throw StateError('Atlantic is resolved above'),
    };
    final colors = _fromSeeds(
      CustomPalette(
        id: palette.name,
        name: palette.name,
        primaryRgb: primary,
        secondaryRgb: secondary,
        tertiaryRgb: tertiary,
      ),
      brightness,
      backgroundOverride: background,
      surfaceOverride: surface,
      containerStrength: isDark ? .27 : .24,
    );
    return colors.copyWith(
      hero: palette == AppPalette.coral
          ? colors.tertiaryContainer
          : colors.primaryContainer,
      divider: Color.lerp(
        colors.surface,
        colors.textPrimary,
        palette == AppPalette.coral ? .28 : .16,
      ),
    );
  }

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  /// Keep user hues where readable; adjust tones centrally for actual surfaces.
  static AppColors forCustom(CustomPalette palette, Brightness brightness) {
    return _fromSeeds(palette, brightness);
  }

  static AppColors _fromSeeds(
    CustomPalette palette,
    Brightness brightness, {
    Color? backgroundOverride,
    Color? surfaceOverride,
    double? containerStrength,
  }) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? dark : light;
    final seeds = [
      palette.primaryRgb,
      palette.secondaryRgb,
      palette.tertiaryRgb,
    ].map((v) => Color(0xFF000000 | v)).toList();
    final background =
        backgroundOverride ??
        Color.lerp(base.background, seeds[0], isDark ? .035 : .015)!;
    final surface =
        surfaceOverride ?? Color.lerp(base.surface, seeds[0], .015)!;
    final variant = Color.lerp(surface, seeds[0], isDark ? .07 : .035)!;
    final containers = seeds
        .map(
          (seed) => Color.lerp(
            surface,
            seed,
            containerStrength ?? (isDark ? .16 : .12),
          )!,
        )
        .toList();
    final bodySurfaces = [background, surface, variant, ...containers];
    final accents = [
      for (var i = 0; i < 3; i++)
        _readable(seeds[i], bodySurfaces, isDark, protectBadges: true),
    ];
    final text = _readable(base.textPrimary, bodySurfaces, isDark);
    final onPrimary =
        _contrast(accents[0], const Color(0xFF000000)) >=
            _contrast(accents[0], const Color(0xFFFFFFFF))
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
    return base.copyWith(
      primary: accents[0],
      primaryContainer: containers[0],
      onPrimary: onPrimary,
      secondary: accents[1],
      secondaryContainer: containers[1],
      tertiary: accents[2],
      tertiaryContainer: containers[2],
      background: background,
      surface: surface,
      surfaceVariant: variant,
      textPrimary: text,
      textSecondary: _readable(base.textSecondary, bodySurfaces, isDark),
      textMuted: _readable(base.textMuted, bodySurfaces, isDark),
      hero: containers[0],
      onHero: text,
      divider: Color.lerp(surface, text, .12),
      outline: Color.lerp(accents[0], text, .35),
    );
  }

  static double _contrast(Color a, Color b) {
    final x = a.computeLuminance(), y = b.computeLuminance();
    return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
  }

  static Color _readable(
    Color color,
    List<Color> surfaces,
    bool dark, {
    bool protectBadges = false,
  }) {
    final target = dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    for (var step = 0; step <= 100; step++) {
      final candidate = Color.lerp(color, target, step / 100)!;
      if (surfaces.every(
        (surface) =>
            _contrast(candidate, surface) >= 4.5 &&
            (!protectBadges ||
                _contrast(
                      candidate,
                      Color.alphaBlend(
                        candidate.withValues(alpha: .12),
                        surface,
                      ),
                    ) >=
                    4.5),
      )) {
        return candidate;
      }
    }
    return target;
  }

  @override
  AppColors copyWith({
    Color? primary,
    Color? primaryContainer,
    Color? onPrimary,
    Color? secondary,
    Color? secondaryContainer,
    Color? tertiary,
    Color? tertiaryContainer,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? divider,
    Color? outline,
    Color? hero,
    Color? onHero,
  }) => AppColors(
    primary: primary ?? this.primary,
    primaryContainer: primaryContainer ?? this.primaryContainer,
    onPrimary: onPrimary ?? this.onPrimary,
    secondary: secondary ?? this.secondary,
    secondaryContainer: secondaryContainer ?? this.secondaryContainer,
    tertiary: tertiary ?? this.tertiary,
    tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceVariant: surfaceVariant ?? this.surfaceVariant,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted: textMuted ?? this.textMuted,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
    info: info ?? this.info,
    divider: divider ?? this.divider,
    outline: outline ?? this.outline,
    hero: hero ?? this.hero,
    onHero: onHero ?? this.onHero,
  );
  @override
  AppColors lerp(covariant AppColors? other, double t) =>
      other == null ? this : _blend(this, other, t);

  static AppColors _blend(
    AppColors a,
    AppColors b,
    double t, {
    Color? primary,
  }) {
    Color mix(Color x, Color y) => Color.lerp(x, y, t) ?? x;
    return AppColors(
      primary: primary ?? mix(a.primary, b.primary),
      primaryContainer: mix(a.primaryContainer, b.primaryContainer),
      onPrimary: mix(a.onPrimary, b.onPrimary),
      secondary: mix(a.secondary, b.secondary),
      secondaryContainer: mix(a.secondaryContainer, b.secondaryContainer),
      tertiary: mix(a.tertiary, b.tertiary),
      tertiaryContainer: mix(a.tertiaryContainer, b.tertiaryContainer),
      background: mix(a.background, b.background),
      surface: mix(a.surface, b.surface),
      surfaceVariant: mix(a.surfaceVariant, b.surfaceVariant),
      textPrimary: mix(a.textPrimary, b.textPrimary),
      textSecondary: mix(a.textSecondary, b.textSecondary),
      textMuted: mix(a.textMuted, b.textMuted),
      success: mix(a.success, b.success),
      warning: mix(a.warning, b.warning),
      danger: mix(a.danger, b.danger),
      info: mix(a.info, b.info),
      divider: mix(a.divider, b.divider),
      outline: mix(a.outline, b.outline),
      hero: mix(a.hero, b.hero),
      onHero: mix(a.onHero, b.onHero),
    );
  }
}
