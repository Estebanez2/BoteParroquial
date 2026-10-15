import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Reference art direction. Color choices stay out of feature widgets.
abstract final class AppGradients {
  static Gradient canvas(BuildContext context) {
    final c = AppColors.of(context);
    return LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        c.primaryContainer.withValues(alpha: .22),
        c.background,
        c.background,
      ],
    );
  }

  static Gradient surface(BuildContext context) {
    final c = AppColors.of(context);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c.surfaceVariant.withValues(alpha: .5), c.surface, c.surface],
    );
  }

  static Gradient hero(BuildContext context) {
    final c = AppColors.of(context);
    return LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [
        Theme.of(context).brightness == Brightness.dark ? c.background : c.hero,
        c.hero,
        Color.lerp(c.hero, c.primary, .2) ?? c.hero,
      ],
    );
  }

  static Gradient primary(BuildContext context) {
    final c = AppColors.of(context);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color.lerp(c.primary, c.onHero, .18) ?? c.primary, c.primary],
    );
  }
}
