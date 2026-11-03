import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';

/// Shared menu content: selection fields, account menu and contextual actions.
class AppMenuRow extends StatelessWidget {
  const AppMenuRow({
    super.key,
    required this.label,
    this.icon = Icons.arrow_outward_rounded,
    this.selected = false,
    this.destructive = false,
  });
  final String label;
  final IconData icon;
  final bool selected, destructive;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final accent = destructive ? c.danger : c.secondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .12),
              borderRadius: AppRadius.control,
            ),
            child: Icon(icon, color: accent, size: AppSpacing.icon),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTypography.of(context).labelLarge.copyWith(
                color: destructive ? c.danger : c.textPrimary,
              ),
            ),
          ),
          if (selected) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.check_circle_rounded,
              color: c.primary,
              size: AppSpacing.icon,
            ),
          ],
        ],
      ),
    );
  }
}
