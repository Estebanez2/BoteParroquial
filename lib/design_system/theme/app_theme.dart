import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import '../../models/appearance_settings.dart';
import '../platform/app_page_transitions.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light, AppColors.light);
  static ThemeData get dark => _build(Brightness.dark, AppColors.dark);
  static ThemeData forPalette(
    AppPalette palette,
    Brightness brightness, {
    AppFont font = AppFont.manrope,
  }) =>
      _build(brightness, AppColors.forPalette(palette, brightness), font: font);
  static ThemeData forSettings(
    AppearanceSettings settings,
    Brightness brightness,
  ) => settings.customPalette == null
      ? forPalette(settings.palette, brightness, font: settings.font)
      : _build(
          brightness,
          AppColors.forCustom(settings.customPalette!, brightness),
          font: settings.font,
        );
  static ThemeData _build(
    Brightness brightness,
    AppColors c, {
    AppFont font = AppFont.manrope,
  }) {
    final family = switch (font) {
      AppFont.manrope => 'Manrope',
      AppFont.newsreader => 'Newsreader',
      AppFont.system => null,
    };
    final typography = AppTypography(c, fontFamily: family);
    final border = OutlineInputBorder(
      borderRadius: AppRadius.control,
      borderSide: BorderSide(color: c.divider),
    );
    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppContextPageTransitionsBuilder(),
          TargetPlatform.iOS: AppCupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: AppCupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: AppContextPageTransitionsBuilder(),
          TargetPlatform.linux: AppContextPageTransitionsBuilder(),
          TargetPlatform.fuchsia: AppContextPageTransitionsBuilder(),
        },
      ),
      brightness: brightness,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: c.primary,
            brightness: brightness,
          ).copyWith(
            primary: c.primary,
            onPrimary: c.onPrimary,
            primaryContainer: c.primaryContainer,
            onPrimaryContainer: c.textPrimary,
            secondary: c.secondary,
            secondaryContainer: c.secondaryContainer,
            onSecondaryContainer: c.textPrimary,
            onSecondary: c.secondary.computeLuminance() > .45
                ? AppColors.light.textPrimary
                : AppColors.light.surface,
            tertiary: c.tertiary,
            tertiaryContainer: c.tertiaryContainer,
            onTertiary: c.tertiary.computeLuminance() > .45
                ? AppColors.light.textPrimary
                : AppColors.light.surface,
            onTertiaryContainer: c.textPrimary,
            surface: c.surface,
            onSurface: c.textPrimary,
            onSurfaceVariant: c.textSecondary,
            error: c.danger,
            outline: c.outline,
            outlineVariant: c.divider,
          ),
      extensions: [c],
      fontFamily: family,
      textTheme: typography.textTheme,
      scaffoldBackgroundColor: c.background,
      dividerColor: c.divider,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: typography.headingSmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        labelStyle: typography.bodyMedium.copyWith(color: c.textSecondary),
        hintStyle: typography.bodyMedium.copyWith(color: c.textMuted),
        helperStyle: typography.bodySmall.copyWith(color: c.textSecondary),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
        errorBorder: border.copyWith(borderSide: BorderSide(color: c.danger)),
        focusedErrorBorder: border.copyWith(
          borderSide: BorderSide(color: c.danger, width: 2),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: c.primaryContainer,
        headerForegroundColor: c.primary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.hero),
        weekdayStyle: typography.labelMedium,
        dayStyle: typography.bodyMedium,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.hero),
        titleTextStyle: typography.headingMedium,
        contentTextStyle: typography.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.extraLarge),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: typography.bodySmall.copyWith(color: c.onPrimary),
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: AppRadius.control,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        position: PopupMenuPosition.under,
        menuPadding: const EdgeInsets.all(AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: c.divider),
        ),
        textStyle: typography.labelLarge,
      ),
    );
  }
}
