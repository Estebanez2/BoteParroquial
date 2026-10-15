import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'app_card.dart';

class AppNavigationTile extends StatelessWidget {
  const AppNavigationTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    variant: AppCardVariant.interactive,
    onTap: onTap,
    semanticLabel: label,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.of(context).primary,
          size: AppSpacing.iconLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(label, style: AppTypography.of(context).bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        const Align(
          alignment: Alignment.centerRight,
          child: Icon(Icons.chevron_right_rounded),
        ),
      ],
    ),
  );
}
