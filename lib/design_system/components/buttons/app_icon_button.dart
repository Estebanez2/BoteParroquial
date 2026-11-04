import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../feedback/app_control_feedback.dart';
import '../feedback/app_sound_scope.dart';

enum AppIconButtonVariant { standard, ghost, danger }

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.variant = AppIconButtonVariant.standard,
    this.sound,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final AppIconButtonVariant variant;
  final UiSound? sound;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppControlFeedback(
      enabled: onPressed != null,
      onActivate: onPressed,
      sound:
          sound ??
          (label.startsWith('Volver') ||
                  icon == Icons.arrow_back_rounded ||
                  icon == Icons.arrow_back ||
                  icon == Icons.arrow_back_ios_new_rounded ||
                  icon == Icons.arrow_back_ios_rounded ||
                  icon == Icons.chevron_left_rounded
              ? UiSound.back
              : UiSound.tap),
      builder: (context, activate) => IconButton(
        tooltip: label,
        onPressed: onPressed == null ? null : activate,
        icon: Icon(icon, size: AppSpacing.iconLarge),
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSpacing.compactHeight),
          backgroundColor: variant == AppIconButtonVariant.standard
              ? c.surfaceVariant
              : Colors.transparent,
          foregroundColor: variant == AppIconButtonVariant.danger
              ? c.danger
              : c.textPrimary,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
          side: BorderSide(
            color: onPressed == null
                ? c.divider
                : variant == AppIconButtonVariant.danger
                ? c.danger
                : c.primary.withValues(alpha: .75),
            width: AppSpacing.actionBorder,
          ),
          elevation: onPressed == null ? 0 : 1,
          shadowColor: c.textPrimary.withValues(alpha: .14),
        ),
      ),
    );
  }
}
