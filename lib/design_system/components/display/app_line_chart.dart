import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../feedback/app_sound_scope.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Presentation only: normalization is geometry, labels retain exact amounts.
class AppLineChart extends StatefulWidget {
  const AppLineChart({
    super.key,
    required this.labels,
    required this.values,
    required this.valueLabels,
  }) : assert(
         labels.length == values.length && values.length == valueLabels.length,
       );
  final List<String> labels, valueLabels;
  final List<int> values;
  @override
  State<AppLineChart> createState() => _AppLineChartState();
}

class _AppLineChartState extends State<AppLineChart> {
  int? _selected;
  @override
  Widget build(BuildContext context) {
    if (widget.values.isEmpty) return const SizedBox.shrink();
    final selected = (_selected ?? widget.values.length - 1).clamp(
      0,
      widget.values.length - 1,
    );
    final c = AppColors.of(context), t = AppTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${widget.labels[selected]} · ${widget.valueLabels[selected]}',
          style: t.headingSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          label: [
            for (var i = 0; i < widget.values.length; i++)
              '${widget.labels[i]}: ${widget.valueLabels[i]}',
          ].join('; '),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              AppSoundScope.emit(context, UiSound.tap);
              final box = context.findRenderObject() as RenderBox;
              final fraction =
                  ((details.localPosition.dx - AppSpacing.md) /
                          (box.size.width - 2 * AppSpacing.md))
                      .clamp(0.0, 1.0);
              setState(
                () =>
                    _selected = (fraction * (widget.values.length - 1)).round(),
              );
            },
            child: SizedBox(
              height: AppSpacing.chartHeight,
              child: CustomPaint(
                painter: _LinePainter(
                  widget.values,
                  selected,
                  c.primary,
                  c.primaryContainer,
                  c.divider,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final label in widget.labels)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: t.bodySmall,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter(
    this.values,
    this.selected,
    this.color,
    this.fill,
    this.grid,
  );
  final List<int> values;
  final int selected;
  final Color color, fill, grid;
  @override
  void paint(Canvas canvas, Size size) {
    final xs = AppSpacing.md, ys = AppSpacing.md;
    final low = values.map((v) => v.toDouble()).reduce(math.min),
        high = values.map((v) => v.toDouble()).reduce(math.max);
    final range = high - low;
    for (var i = 0; i < 4; i++) {
      final y = ys + (size.height - 2 * ys) * i / 3;
      canvas.drawLine(
        Offset(xs, y),
        Offset(size.width - xs, y),
        Paint()
          ..color = grid
          ..strokeWidth = 1,
      );
    }
    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(
          xs + (size.width - 2 * xs) * i / math.max(1, values.length - 1),
          range == 0
              ? size.height / 2
              : size.height -
                    ys -
                    ((values[i].toDouble() - low) / range) *
                        (size.height - 2 * ys),
        ),
    ];
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    final area = Path.from(line)
      ..lineTo(points.last.dx, size.height - ys)
      ..lineTo(points.first.dx, size.height - ys)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fill, fill.withValues(alpha: .1)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(
        points[i],
        i == selected ? 6 : 3,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values != values ||
      old.selected != selected ||
      old.color != color ||
      old.fill != fill ||
      old.grid != grid;
}
