import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// A simple communal mark: two overlapping forms sharing a center.
class AppBrand extends StatelessWidget {
  const AppBrand({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppSpacing.xxxl,
          height: AppSpacing.xxxl,
          decoration: BoxDecoration(
            color: c.primaryContainer,
            borderRadius: AppRadius.control,
          ),
          child: CustomPaint(painter: _BrandPainter(c.primary)),
        ),
        if (!compact) ...[
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              'BoteParroquial',
              style: AppTypography.of(context).headingSmall,
            ),
          ),
        ],
      ],
    );
  }
}

class _BrandPainter extends CustomPainter {
  const _BrandPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .23,
          size.height * .22,
          size.width * .35,
          size.height * .56,
        ),
        const Radius.circular(AppRadius.small),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .42,
          size.height * .22,
          size.width * .35,
          size.height * .56,
        ),
        const Radius.circular(AppRadius.small),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BrandPainter oldDelegate) => oldDelegate.color != color;
}
