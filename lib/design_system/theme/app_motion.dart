import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const durationFast = Duration(milliseconds: 140);
  static const durationNormal = Duration(milliseconds: 220);
  static const durationSlow = Duration(milliseconds: 320);
  static const statusNoticeDelay = Duration(seconds: 2);
  static const curveStandard = Curves.easeOutCubic;
  static const curveEmphasized = Curves.easeInOutCubic;
  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;
}

/// A single, restrained entry animation. Honors system reduced-motion settings.
class AppReveal extends StatelessWidget {
  const AppReveal({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: AppMotion.duration(context, AppMotion.durationSlow),
    curve: AppMotion.curveStandard,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - value)),
        child: child,
      ),
    ),
    child: child,
  );
}
