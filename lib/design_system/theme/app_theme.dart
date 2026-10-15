import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light, AppColors.light);
  static ThemeData get dark => _build(Brightness.dark, AppColors.dark);
  static ThemeData _build(Brightness brightness, AppColors c) {
    final typography = AppTypography(c);
    final border = OutlineInputBorder(
      borderRadius: AppRadius.control,
      borderSide: BorderSide(color: c.outline),
    );
    return ThemeData(
      useMaterial3: true,
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
            surface: c.surface,
            onSurface: c.textPrimary,
            onSurfaceVariant: c.textSecondary,
            error: c.danger,
            outline: c.outline,
            outlineVariant: c.divider,
          ),
      extensions: [c],
      fontFamily: 'Manrope',
      textTheme: typography.textTheme,
      scaffoldBackgroundColor: c.background,
      dividerColor: c.divider,
      splashFactory: InkSparkle.splashFactory,
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
        fillColor: c.surface,
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
    );
  }
}
