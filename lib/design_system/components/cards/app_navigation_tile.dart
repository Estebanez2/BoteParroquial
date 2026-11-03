import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_radius.dart';
import 'app_card.dart';
import '../display/app_badge.dart';

class AppNavigationTile extends StatelessWidget {
  const AppNavigationTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.description,
    this.tone = AppTone.primary,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? description;
  final AppTone tone;
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    variant: AppCardVariant.interactive,
    onTap: onTap,
    semanticLabel: label,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AppSpacing.coverLarge * 2;
        final symbol = Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: toneColor(context, tone).withValues(alpha: .1),
            borderRadius: AppRadius.control,
          ),
          child: Icon(
            icon,
            color: toneColor(context, tone),
            size: AppSpacing.iconLarge,
          ),
        );
        final chevron = Icon(
          Icons.chevron_right_rounded,
          color: AppColors.of(context).textMuted,
          size: AppSpacing.icon,
        );
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: compact && description == null
                  ? AppTypography.of(context).labelMedium
                  : AppTypography.of(context).labelLarge,
            ),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                description!,
                style: AppTypography.of(
                  context,
                ).bodySmall.copyWith(color: AppColors.of(context).textMuted),
              ),
            ],
          ],
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [symbol, const Spacer(), chevron]),
              const SizedBox(height: AppSpacing.md),
              text,
            ],
          );
        }
        return Row(
          children: [
            symbol,
            const SizedBox(width: AppSpacing.md),
            Expanded(child: text),
            chevron,
          ],
        );
      },
    ),
  );
}
