import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'app_card.dart';
import '../display/app_badge.dart';

class StatisticCard extends StatelessWidget {
  const StatisticCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    this.framed = true,
    this.tone = AppTone.primary,
  });
  final String label, value;
  final IconData icon;
  final String? caption;
  final bool framed;
  final AppTone tone;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTypography.of(context);
    final accent = toneColor(context, tone);
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final symbol = Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: accent, size: AppSpacing.icon),
        );
        final title = Text(
          label,
          style: t.bodySmall.copyWith(color: c.textSecondary),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (constraints.maxWidth < AppSpacing.coverLarge * 1.5) ...[
              symbol,
              const SizedBox(height: AppSpacing.sm),
              title,
            ] else
              Row(
                children: [
                  symbol,
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: title),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            Text(
              value,
              style:
                  (constraints.maxWidth < AppSpacing.coverLarge * 1.5
                          ? t.moneyMedium
                          : t.statisticValue)
                      .copyWith(color: accent),
            ),
            if (caption != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(caption!, style: t.bodySmall.copyWith(color: c.textMuted)),
            ],
          ],
        );
      },
    );
    return framed ? AppCard(child: content) : content;
  }
}
