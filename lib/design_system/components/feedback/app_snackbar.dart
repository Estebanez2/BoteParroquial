import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../display/app_badge.dart';

enum AppSnackbarVariant { success, error, warning, info }

abstract final class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    AppSnackbarVariant variant = AppSnackbarVariant.info,
  }) {
    final c = AppColors.of(context);
    final tone = switch (variant) {
      AppSnackbarVariant.success => AppTone.success,
      AppSnackbarVariant.error => AppTone.danger,
      AppSnackbarVariant.warning => AppTone.warning,
      AppSnackbarVariant.info => AppTone.info,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.control,
            side: BorderSide(color: c.divider),
          ),
          content: Row(
            children: [
              Icon(switch (variant) {
                AppSnackbarVariant.success => Icons.check_circle_outline,
                AppSnackbarVariant.error => Icons.error_outline,
                AppSnackbarVariant.warning => Icons.warning_amber_rounded,
                _ => Icons.info_outline,
              }, color: toneColor(context, tone)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.of(context).bodyMedium,
                ),
              ),
            ],
          ),
          showCloseIcon: true,
          closeIconColor: c.textSecondary,
        ),
      );
  }
}
