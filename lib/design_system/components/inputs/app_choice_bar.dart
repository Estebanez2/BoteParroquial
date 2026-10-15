import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class AppChoiceBar<T> extends StatelessWidget {
  const AppChoiceBar({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final buttons = [
      for (final entry in options.entries)
        Expanded(
          child: Semantics(
            selected: value == entry.key,
            child: AnimatedContainer(
              duration: AppMotion.duration(context, AppMotion.durationNormal),
              decoration: BoxDecoration(
                borderRadius: AppRadius.control,
                gradient: value == entry.key
                    ? AppGradients.primary(context)
                    : null,
              ),
              child: TextButton(
                onPressed: enabled ? () => onChanged(entry.key) : null,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.controlHeight),
                  foregroundColor: value == entry.key
                      ? c.onPrimary
                      : c.textPrimary,
                  textStyle: AppTypography.of(context).labelLarge,
                ),
                child: Text(entry.value, textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        borderRadius: AppRadius.control,
        border: Border.all(color: c.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: buttons,
      ),
    );
  }
}
