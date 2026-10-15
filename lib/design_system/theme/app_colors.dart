import 'package:flutter/material.dart';

/// Semantic palette. Always resolve from context so dark mode remains automatic.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.secondary,
    required this.secondaryContainer,
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
  final Color background, surface, surfaceVariant;
  final Color textPrimary, textSecondary, textMuted;
  final Color success, warning, danger, info, divider, outline;
  final Color hero, onHero;

  static const light = AppColors(
    primary: Color(0xFF22594D),
    primaryContainer: Color(0xFFE0EEE6),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF9A503A),
    secondaryContainer: Color(0xFFF5E6DE),
    background: Color(0xFFF7F6F1),
    surface: Color(0xFFFFFEFA),
    surfaceVariant: Color(0xFFEEEFE8),
    textPrimary: Color(0xFF20372F),
    textSecondary: Color(0xFF52645B),
    textMuted: Color(0xFF66736B),
    success: Color(0xFF236749),
    warning: Color(0xFF88591A),
    danger: Color(0xFFB23E3E),
    info: Color(0xFF345F87),
    divider: Color(0xFFE2E5DC),
    outline: Color(0xFF818D82),
    hero: Color(0xFF193F35),
    onHero: Color(0xFFF5F5E9),
  );
  static const dark = AppColors(
    primary: Color(0xFFA6F1D0),
    primaryContainer: Color(0xFF123E2D),
    onPrimary: Color(0xFF032117),
    secondary: Color(0xFFFFA190),
    secondaryContainer: Color(0xFF54372D),
    background: Color(0xFF020E09),
    surface: Color(0xFF081C14),
    surfaceVariant: Color(0xFF153B2B),
    textPrimary: Color(0xFFF5F7F1),
    textSecondary: Color(0xFFC0CFC4),
    textMuted: Color(0xFF9DB3A5),
    success: Color(0xFF92E7C2),
    warning: Color(0xFFF0CB88),
    danger: Color(0xFFFF9987),
    info: Color(0xFFA9CEEE),
    divider: Color(0xFF264C3B),
    outline: Color(0xFF4E8D70),
    hero: Color(0xFF104A34),
    onHero: Color(0xFFF5F9F0),
  );
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  AppColors copyWith({
    Color? primary,
    Color? primaryContainer,
    Color? onPrimary,
    Color? secondary,
    Color? secondaryContainer,
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
