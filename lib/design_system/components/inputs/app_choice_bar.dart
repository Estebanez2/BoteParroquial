import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../feedback/app_control_feedback.dart';

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
                    ? AppGradients.surface(context)
                    : null,
                border: Border.all(
                  color: value == entry.key ? c.outline : Colors.transparent,
                ),
              ),
              child: AppControlFeedback(
                enabled: enabled,
                onActivate: () => onChanged(entry.key),
                builder: (_, activate) => SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: enabled ? activate : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.md,
                      ),
                      minimumSize: const Size(
                        double.infinity,
                        AppSpacing.controlHeight,
                      ),
                      foregroundColor: value == entry.key
                          ? c.primary
                          : c.textSecondary,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.control,
                      ),
                      textStyle: AppTypography.of(context).labelLarge,
                    ),
                    child: Text(entry.value, textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        borderRadius: AppRadius.control,
        color: c.background,
        border: Border.all(color: c.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: buttons,
      ),
    );
  }
}
