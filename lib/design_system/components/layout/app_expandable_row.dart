import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';

class AppExpandableRow extends StatelessWidget {
  const AppExpandableRow({
    super.key,
    required this.title,
    required this.children,
    this.leading,
    this.expanded = false,
  });
  final Widget title;
  final Widget? leading;
  final List<Widget> children;
  final bool expanded;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ExpansionTile(
      initiallyExpanded: expanded,
      expansionAnimationStyle: AnimationStyle(
        duration: AppMotion.duration(context, AppMotion.durationSlow),
        reverseDuration: AppMotion.duration(context, AppMotion.durationNormal),
        curve: AppMotion.curveStandard,
      ),
      tilePadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      childrenPadding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.lg,
      ),
      collapsedBackgroundColor: c.primaryContainer.withValues(alpha: .18),
      backgroundColor: c.primaryContainer.withValues(alpha: .10),
      clipBehavior: Clip.antiAlias,
      iconColor: c.primary,
      collapsedIconColor: c.textSecondary,
      textColor: c.textPrimary,
      collapsedTextColor: c.textPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.control,
        side: BorderSide(
          color: c.primary.withValues(alpha: .75),
          width: AppSpacing.actionBorder,
        ),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: AppRadius.control,
        side: BorderSide(
          color: c.primary.withValues(alpha: .75),
          width: AppSpacing.actionBorder,
        ),
      ),
      leading: MediaQuery.textScalerOf(context).scale(1) > 1.3 ? null : leading,
      title: DefaultTextStyle(
        style: AppTypography.of(context).bodyMedium,
        child: title,
      ),
      children: children,
    );
  }
}
