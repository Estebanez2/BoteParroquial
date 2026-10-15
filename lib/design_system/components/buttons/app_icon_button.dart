import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

enum AppIconButtonVariant { standard, ghost, danger }

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.variant = AppIconButtonVariant.standard,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final AppIconButtonVariant variant;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(icon, size: AppSpacing.iconLarge),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(AppSpacing.compactHeight),
        backgroundColor: variant == AppIconButtonVariant.standard
            ? c.surfaceVariant.withValues(alpha: .65)
            : Colors.transparent,
        foregroundColor: variant == AppIconButtonVariant.danger
            ? c.danger
            : c.textPrimary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
        side: variant == AppIconButtonVariant.standard
            ? BorderSide(color: c.outline.withValues(alpha: .4))
            : null,
      ),
    );
  }
}
