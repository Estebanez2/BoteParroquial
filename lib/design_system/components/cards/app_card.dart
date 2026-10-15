import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_gradients.dart';

enum AppCardVariant { standard, elevated, outlined, interactive }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.standard,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.semanticLabel,
  });
  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      label: semanticLabel,
      container: true,
      child: AnimatedContainer(
        duration: AppMotion.duration(context, AppMotion.durationNormal),
        decoration: BoxDecoration(
          gradient: AppGradients.surface(context),
          borderRadius: AppRadius.card,
          border: Border.all(
            color: variant == AppCardVariant.outlined ? c.outline : c.divider,
          ),
          boxShadow: variant == AppCardVariant.elevated
              ? AppShadows.soft(context)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.card,
          child: InkWell(
            onTap: variant == AppCardVariant.interactive ? onTap : null,
            borderRadius: AppRadius.card,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
