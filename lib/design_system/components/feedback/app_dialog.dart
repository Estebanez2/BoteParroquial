import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../buttons/app_button.dart';
import '../display/app_badge.dart';

enum AppDialogVariant { information, confirmation, warning, danger }

abstract final class AppDialog {
  /// Returns false on explicit cancellation, back, escape, or barrier dismissal.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String description,
    String confirmLabel = 'Entendido',
    String cancelLabel = 'Cancelar',
    AppDialogVariant variant = AppDialogVariant.information,
  }) async {
    final tone = switch (variant) {
      AppDialogVariant.warning => AppTone.warning,
      AppDialogVariant.danger => AppTone.danger,
      _ => AppTone.primary,
    };
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(switch (variant) {
          AppDialogVariant.warning ||
          AppDialogVariant.danger => Icons.warning_amber_rounded,
          _ => Icons.info_outline,
        }, color: toneColor(context, tone)),
        title: Text(title),
        content: Text(description),
        contentPadding: const EdgeInsets.all(AppSpacing.xl),
        actions: [
          if (variant != AppDialogVariant.information)
            AppButton(
              label: cancelLabel,
              onPressed: () => Navigator.pop(context, false),
              variant: AppButtonVariant.ghost,
            ),
          AppButton(
            label: confirmLabel,
            onPressed: () => Navigator.pop(context, true),
            variant: variant == AppDialogVariant.danger
                ? AppButtonVariant.destructive
                : AppButtonVariant.primary,
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
