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
    this.framed = true,
  });
  final String label, value;
  final IconData icon;
  final String? caption;
  final bool framed;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTypography.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: c.primary, size: AppSpacing.iconLarge),
        const SizedBox(height: AppSpacing.lg),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: t.statisticValue),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: t.bodyMedium.copyWith(color: c.textSecondary)),
        if (caption != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(caption!, style: t.bodySmall.copyWith(color: c.textMuted)),
        ],
      ],
    );
    return framed ? AppCard(child: content) : content;
  }
}
