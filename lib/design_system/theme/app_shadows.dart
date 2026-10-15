import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppShadows {
  static List<BoxShadow> soft(BuildContext context) => [
    BoxShadow(
      color: AppColors.of(context).hero.withValues(alpha: 0.07),
      blurRadius: 24,
      offset: const Offset(0, 6),
    ),
  ];
  static List<BoxShadow> floating(BuildContext context) => [
    BoxShadow(
      color: AppColors.of(context).hero.withValues(alpha: 0.14),
      blurRadius: 40,
      offset: const Offset(0, 12),
    ),
  ];
}
