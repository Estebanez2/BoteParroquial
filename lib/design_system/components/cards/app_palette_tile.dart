import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'app_card.dart';

class AppPaletteTile extends StatelessWidget {
  const AppPaletteTile({
    super.key,
    required this.label,
    required this.description,
    required this.light,
    required this.dark,
    required this.selected,
    required this.onTap,
  });
  final String label, description;
  final AppColors light, dark;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: AppCard(
      variant: AppCardVariant.interactive,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.of(context).headingSmall,
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected
                    ? AppColors.of(context).primary
                    : AppColors.of(context).textMuted,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(description, style: AppTypography.of(context).bodySmall),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _Sample(colors: light, label: 'Claro'),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Sample(colors: dark, label: 'Oscuro'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Sample extends StatelessWidget {
  const _Sample({required this.colors, required this.label});
  final AppColors colors;
  final String label;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: AppRadius.control,
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSpacing.iconLarge,
                height: AppSpacing.iconLarge,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: AppSpacing.icon,
                height: AppSpacing.icon,
                decoration: BoxDecoration(
                  color: colors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                width: AppSpacing.lg,
                height: AppSpacing.lg,
                decoration: BoxDecoration(
                  color: colors.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  height: AppSpacing.sm,
                  color: colors.surfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: AppTypography(
              colors,
              fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
            ).labelMedium,
          ),
        ],
      ),
    ),
  );
}
