import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../buttons/app_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title, description;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: c.primaryContainer,
              borderRadius: AppRadius.card,
            ),
            child: Icon(icon, size: AppSpacing.xxl, color: c.primary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(title, style: t.headingSmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: t.bodyMedium.copyWith(color: c.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: AppButtonVariant.outline,
            ),
          ],
        ],
      ),
    );
  }
}
