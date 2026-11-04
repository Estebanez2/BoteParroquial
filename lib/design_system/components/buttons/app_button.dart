import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_shadows.dart';
import '../feedback/loading_indicator.dart';
import '../feedback/app_control_feedback.dart';
import '../feedback/app_sound_scope.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, destructive }

enum AppButtonSize { normal, compact }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.normal,
    this.loading = false,
    this.fullWidth = false,
    this.leadingIcon,
    this.trailingIcon,
    this.validate,
    this.tapEffect,
    this.sound,
    this.soundEnabled = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool loading, fullWidth;
  final IconData? leadingIcon, trailingIcon;
  final bool Function()? validate;
  final AppTapEffect? tapEffect;
  final UiSound? sound;
  final bool soundEnabled;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final background = switch (variant) {
      AppButtonVariant.primary => Colors.transparent,
      AppButtonVariant.secondary => c.secondaryContainer,
      AppButtonVariant.destructive => c.danger,
      AppButtonVariant.outline => c.primaryContainer.withValues(alpha: .40),
      AppButtonVariant.ghost => c.primaryContainer.withValues(alpha: .18),
    };
    final foreground = switch (variant) {
      AppButtonVariant.primary => c.onPrimary,
      AppButtonVariant.secondary => c.secondary,
      AppButtonVariant.destructive => Theme.of(context).colorScheme.onError,
      _ => c.primary,
    };
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          LoadingIndicator(
            size: AppSpacing.icon,
            color: foreground,
            label: '$label, en curso',
          )
        else if (leadingIcon != null)
          Icon(leadingIcon, size: AppSpacing.icon),
        if (loading || leadingIcon != null)
          const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
        if (!loading && trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(trailingIcon, size: AppSpacing.icon),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: AppControlFeedback(
        enabled: onPressed != null && !loading,
        busy: loading,
        validate: validate,
        effect:
            tapEffect ??
            (variant == AppButtonVariant.primary ||
                    variant == AppButtonVariant.destructive
                ? AppTapEffect.shine
                : AppTapEffect.wave),
        color: foreground,
        onActivate: onPressed,
        soundEnabled: soundEnabled,
        sound:
            sound ?? (label.startsWith('Volver') ? UiSound.back : UiSound.tap),
        builder: (context, activate) => SizedBox(
          width: fullWidth ? double.infinity : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.control,
              boxShadow: onPressed != null && !loading
                  ? AppShadows.action(context)
                  : null,
              gradient:
                  variant == AppButtonVariant.primary &&
                      (onPressed != null || loading)
                  ? AppGradients.primary(context)
                  : null,
            ),
            child: TextButton(
              onPressed: loading || onPressed == null ? null : activate,
              style: ButtonStyle(
                animationDuration: AppMotion.duration(
                  context,
                  AppMotion.durationFast,
                ),
                minimumSize: WidgetStatePropertyAll(
                  Size(
                    0,
                    size == AppButtonSize.normal
                        ? AppSpacing.controlHeight
                        : AppSpacing.compactHeight,
                  ),
                ),
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(
                    horizontal: size == AppButtonSize.normal
                        ? AppSpacing.xl
                        : AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                textStyle: WidgetStatePropertyAll(
                  AppTypography.of(context).labelLarge,
                ),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.disabled) && !loading
                      ? c.surfaceVariant
                      : background,
                ),
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.disabled) && !loading
                      ? c.textMuted
                      : foreground,
                ),
                overlayColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.focused)
                      ? foreground.withValues(alpha: .18)
                      : foreground.withValues(alpha: .08),
                ),
                shape: const WidgetStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: AppRadius.control),
                ),
                side: WidgetStateProperty.resolveWith(
                  (states) => BorderSide(
                    color: states.contains(WidgetState.disabled) && !loading
                        ? c.divider
                        : variant == AppButtonVariant.primary ||
                              variant == AppButtonVariant.destructive
                        ? foreground.withValues(alpha: .55)
                        : foreground.withValues(alpha: .75),
                    width: states.contains(WidgetState.focused)
                        ? AppSpacing.focusBorder
                        : AppSpacing.actionBorder,
                  ),
                ),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
