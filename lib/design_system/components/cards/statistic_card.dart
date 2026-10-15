import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'app_card.dart';

class StatisticCard extends StatelessWidget {
  const StatisticCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
  });
  final String label, value;
  final IconData icon;
  final String? caption;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTypography.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c.secondary, size: AppSpacing.iconLarge),
          const SizedBox(height: AppSpacing.lg),
          Text(value, style: t.statisticValue),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: t.bodyMedium.copyWith(color: c.textSecondary)),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(caption!, style: t.bodySmall.copyWith(color: c.textMuted)),
          ],
        ],
      ),
    );
  }
}
