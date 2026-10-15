import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class AppSection extends StatelessWidget {
  const AppSection({
    super.key,
    required this.title,
    required this.child,
    this.description,
    this.eyebrow,
  });
  final String title;
  final Widget child;
  final String? description, eyebrow;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            Text(eyebrow!, style: t.labelSmall.copyWith(color: c.secondary)),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(title, style: t.sectionTitle),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              description!,
              style: t.bodyMedium.copyWith(color: c.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          child,
        ],
      ),
    );
  }
}
