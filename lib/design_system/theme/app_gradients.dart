import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Reference art direction. Color choices stay out of feature widgets.
abstract final class AppGradients {
  static Gradient canvas(BuildContext context) {
    final c = AppColors.of(context);
    return LinearGradient(colors: [c.background, c.background]);
  }

  static Gradient surface(BuildContext context) {
    final c = AppColors.of(context);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c.surface, c.surface],
    );
  }

  static Gradient hero(BuildContext context) {
    final c = AppColors.of(context);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c.hero, c.tertiaryContainer, c.secondaryContainer],
    );
  }

  static Gradient primary(BuildContext context) {
    final c = AppColors.of(context);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c.primary, c.primary],
    );
  }
}
