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
    borderRadius: AppRadius.card,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.hero(context),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.of(context).outline),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _Rings(AppColors.of(context).primary),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: child),
        ],
      ),
    ),
  );
}

class _Rings extends CustomPainter {
  const _Rings(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .14)
      ..style = PaintingStyle.stroke;
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(
        Offset(size.width, 0),
        size.width * (.18 + i * .13),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Rings oldDelegate) => color != oldDelegate.color;
}
