import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';

/// Decorative orbits, deliberately unrelated to balances, trends or coverage.
/// Plays once on entry; never starts a continuous background ticker.
class AppAtmosphere extends StatelessWidget {
  const AppAtmosphere({super.key});
  @override
  Widget build(BuildContext context) {
    final color = AppColors.of(context).onHero;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: reduced ? 1 : 0, end: 1),
            duration: AppMotion.duration(context, AppMotion.durationAtmosphere),
            curve: AppMotion.curveStandard,
            builder: (context, value, _) => CustomPaint(
              painter: _OrbitPainter(color, value),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter(this.color, this.progress);
  final Color color;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 1.02, size.height * .12);
    final radius = math.min(size.width, AppSpacing.ornamentSize);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSpacing.ornamentStroke;
    for (var i = 0; i < 4; i++) {
      final r = radius * (.45 + i * .24);
      line.color = color.withValues(alpha: (.13 - i * .025) * progress);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        math.pi * (.35 + .08 * (1 - progress)),
        math.pi * 1.55 * progress,
        false,
        line,
      );
      final angle = math.pi * (.72 + i * .13);
      canvas.drawCircle(
        center + Offset(math.cos(angle) * r, math.sin(angle) * r),
        AppSpacing.xs * .65,
        Paint()..color = color.withValues(alpha: .3 * progress),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) =>
      color != oldDelegate.color || progress != oldDelegate.progress;
}
