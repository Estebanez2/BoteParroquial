import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class AppHeroPanel extends StatelessWidget {
  const AppHeroPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: AppRadius.hero,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.hero(context),
        borderRadius: AppRadius.hero,
        border: Border.all(color: AppColors.of(context).divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: child,
      ),
    ),
  );
}
