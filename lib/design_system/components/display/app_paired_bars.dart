import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class AppBarPair {
  const AppBarPair({
    required this.label,
    required this.first,
    required this.second,
    required this.firstText,
    required this.secondText,
  });
  final String label, firstText, secondText;
  final int first, second;
}

/// Display geometry only. Values and accessible formatted labels come from callers.
class AppPairedBars extends StatelessWidget {
  const AppPairedBars({
    super.key,
    required this.entries,
    required this.firstLabel,
    required this.secondLabel,
  });
  final List<AppBarPair> entries;
  final String firstLabel, secondLabel;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context), type = AppTypography.of(context);
    var maximum = 1;
    for (final entry in entries) {
      if (entry.first > maximum) maximum = entry.first;
      if (entry.second > maximum) maximum = entry.second;
    }
    Widget bar(int value, Color color) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: (value / maximum).clamp(0, 1)),
      duration: AppMotion.duration(context, AppMotion.durationNormal),
      builder: (_, progress, _) => LinearProgressIndicator(
        value: progress,
        minHeight: AppSpacing.sm,
        color: color,
        backgroundColor: colors.surfaceVariant,
        borderRadius: AppRadius.control,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Semantics(
              label:
                  '${entry.label}. $firstLabel: ${entry.firstText}. $secondLabel: ${entry.secondText}.',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(entry.label, style: type.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Text(
                        '$firstLabel ${entry.firstText}',
                        style: type.bodySmall.copyWith(color: colors.success),
                      ),
                      Text(
                        '$secondLabel ${entry.secondText}',
                        style: type.bodySmall.copyWith(color: colors.danger),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  bar(entry.first, colors.success),
                  const SizedBox(height: AppSpacing.xs),
                  bar(entry.second, colors.danger),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
