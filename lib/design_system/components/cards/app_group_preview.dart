import 'package:flutter/material.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../feedback/app_control_feedback.dart';
import '../layout/app_adaptive_row.dart';
import 'app_card.dart';

/// Group entry composition; data and navigation remain with the feature.
class AppGroupPreview extends StatelessWidget {
  const AppGroupPreview({
    super.key,
    required this.cover,
    required this.title,
    required this.balance,
    required this.onTap,
    this.description,
  });
  final Widget cover, balance;
  final String title;
  final String? description;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return ClipRRect(
      borderRadius: AppRadius.card,
      child: AppCard(
        semanticLabel: 'Abrir $title',
        padding: EdgeInsets.zero,
        variant: AppCardVariant.interactive,
        tapEffect: AppTapEffect.none,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.large - AppSpacing.actionBorder),
              ),
              child: cover,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: AppAdaptiveRow(
                children: [
                  Text(
                    description ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall,
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topRight,
                      child: balance,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
