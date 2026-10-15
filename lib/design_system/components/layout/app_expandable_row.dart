import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

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
      tilePadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.lg),
      iconColor: c.primary,
      collapsedIconColor: c.textSecondary,
      textColor: c.textPrimary,
      collapsedTextColor: c.textPrimary,
      shape: const Border(),
      collapsedShape: const Border(),
      leading: MediaQuery.textScalerOf(context).scale(1) > 1.3 ? null : leading,
      title: DefaultTextStyle(
        style: AppTypography.of(context).bodyMedium,
        child: title,
      ),
      children: children,
    );
  }
}
