import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

enum AppTone {
  neutral,
  primary,
  secondary,
  tertiary,
  success,
  warning,
  danger,
  info,
}

Color toneColor(BuildContext context, AppTone tone) {
  final c = AppColors.of(context);
  return switch (tone) {
    AppTone.neutral => c.textSecondary,
    AppTone.primary => c.primary,
    AppTone.secondary => c.secondary,
    AppTone.tertiary => c.tertiary,
    AppTone.success => c.success,
    AppTone.warning => c.warning,
    AppTone.danger => c.danger,
    AppTone.info => c.info,
  };
}

class AppBadge extends StatelessWidget {
  const AppBadge(
    this.label, {
    super.key,
    this.tone = AppTone.neutral,
    this.icon,
  });
  final String label;
  final AppTone tone;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final color = toneColor(context, tone);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.xs,
          children: [
            if (icon != null) Icon(icon, color: color, size: AppSpacing.lg),
            Text(
              label,
              style: AppTypography.of(
                context,
              ).labelMedium.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
