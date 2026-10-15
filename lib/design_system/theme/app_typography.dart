import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  const AppTypography(this.colors);
  final AppColors colors;
  static AppTypography of(BuildContext context) =>
      AppTypography(AppColors.of(context));
  TextStyle _style(
    double size,
    FontWeight weight, {
    double height = 1.45,
    double spacing = 0,
  }) => TextStyle(
    fontFamily: 'Manrope',
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: spacing,
    color: colors.textPrimary,
  );
  TextStyle get displayLarge => _style(
    48,
    FontWeight.w400,
    height: 1.08,
    spacing: -1.5,
  ).copyWith(fontFamily: 'Newsreader');
  TextStyle get headingLarge =>
      _style(30, FontWeight.w700, height: 1.2, spacing: -0.9);
  TextStyle get headingMedium =>
      _style(24, FontWeight.w700, height: 1.25, spacing: -0.6);
  TextStyle get headingSmall =>
      _style(19, FontWeight.w700, height: 1.3, spacing: -0.3);
  TextStyle get bodyLarge => _style(16, FontWeight.w400);
  TextStyle get bodyMedium => _style(14, FontWeight.w400);
  TextStyle get bodySmall => _style(12, FontWeight.w400);
  TextStyle get labelLarge => _style(14, FontWeight.w700, height: 1.3);
  TextStyle get labelMedium =>
      _style(12, FontWeight.w700, height: 1.3, spacing: 0.2);
  TextStyle get labelSmall =>
      _style(11, FontWeight.w700, height: 1.3, spacing: 0.7);
  TextStyle get moneyHero => _style(
    48,
    FontWeight.w600,
    height: 1.15,
    spacing: -1.8,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  TextStyle get moneyLarge => _style(
    30,
    FontWeight.w600,
    height: 1.2,
    spacing: -0.8,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  TextStyle get moneyMedium => _style(
    20,
    FontWeight.w600,
    height: 1.3,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  TextStyle get sectionTitle => headingSmall;
  TextStyle get statisticValue => moneyLarge;
  TextStyle get movementAmount => moneyMedium;
  TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    headlineLarge: headingLarge,
    headlineMedium: headingMedium,
    headlineSmall: headingSmall,
    titleLarge: headingSmall,
    titleMedium: labelLarge,
    titleSmall: labelMedium,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
