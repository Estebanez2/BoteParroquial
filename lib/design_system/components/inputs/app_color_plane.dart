import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Two-dimensional HSV choice, shared by every AppColorField.
class AppColorPlane extends StatelessWidget {
  const AppColorPlane({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final HSVColor value;
  final ValueChanged<HSVColor> onChanged;
  @override
  Widget build(BuildContext context) => Focus(
    onKeyEvent: (_, event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
        return KeyEventResult.ignored;
      }
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.arrowRight) {
        onChanged(
          value.withSaturation(
            (value.saturation +
                    (key == LogicalKeyboardKey.arrowRight ? .02 : -.02))
                .clamp(0, 1),
          ),
        );
      } else if (key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowDown) {
        onChanged(
          value.withValue(
            (value.value + (key == LogicalKeyboardKey.arrowUp ? .02 : -.02))
                .clamp(0, 1),
          ),
        );
      } else {
        return KeyEventResult.ignored;
      }
      return KeyEventResult.handled;
    },
    child: Semantics(
      label: 'Cuadrado de color',
      value:
          'Intensidad ${(value.saturation * 100).round()} %, luminosidad ${(value.value * 100).round()} %',
      increasedValue:
          'Intensidad ${((value.saturation + .05).clamp(0, 1) * 100).round()} %, luminosidad ${(value.value * 100).round()} %',
      decreasedValue:
          'Intensidad ${((value.saturation - .05).clamp(0, 1) * 100).round()} %, luminosidad ${(value.value * 100).round()} %',
      hint:
          'Arrastra para elegir. Con teclado, izquierda y derecha cambian intensidad; arriba y abajo, luminosidad.',
      focusable: true,
      onIncrease: () =>
          onChanged(value.withSaturation((value.saturation + .05).clamp(0, 1))),
      onDecrease: () =>
          onChanged(value.withSaturation((value.saturation - .05).clamp(0, 1))),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            void choose(Offset position) => onChanged(
              value
                  .withSaturation(
                    (position.dx / constraints.maxWidth).clamp(0, 1),
                  )
                  .withValue(
                    (1 - position.dy / constraints.maxHeight).clamp(0, 1),
                  ),
            );
            return MouseRegion(
              cursor: SystemMouseCursors.precise,
              child: GestureDetector(
                onTapDown: (details) => choose(details.localPosition),
                onPanStart: (details) => choose(details.localPosition),
                onPanUpdate: (details) => choose(details.localPosition),
                child: CustomPaint(
                  painter: _ColorPlanePainter(
                    value,
                    AppColors.of(context).outline,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _ColorPlanePainter extends CustomPainter {
  const _ColorPlanePainter(this.value, this.border);
  final HSVColor value;
  final Color border;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(AppRadius.medium),
    );
    canvas.save();
    canvas.clipRRect(shape);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white,
            HSVColor.fromAHSV(1, value.hue, 1, 1).toColor(),
          ],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
    canvas.restore();
    canvas.drawRRect(
      shape,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke,
    );
    final radius = AppSpacing.sm;
    final point = Offset(
      (value.saturation * size.width).clamp(
        radius + 2,
        size.width - radius - 2,
      ),
      ((1 - value.value) * size.height).clamp(
        radius + 2,
        size.height - radius - 2,
      ),
    );
    canvas.drawCircle(point, radius + 2, Paint()..color = Colors.black);
    canvas.drawCircle(point, radius, Paint()..color = Colors.white);
    canvas.drawCircle(point, radius - 2, Paint()..color = value.toColor());
  }

  @override
  bool shouldRepaint(_ColorPlanePainter old) =>
      old.value != value || old.border != border;
}

class AppHueSlider extends StatelessWidget {
  const AppHueSlider({super.key, required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Barra arcoíris',
    child: Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Container(
            height: AppSpacing.md,
            decoration: BoxDecoration(
              borderRadius: AppRadius.control,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF0000),
                  Color(0xFFFFFF00),
                  Color(0xFF00FF00),
                  Color(0xFF00FFFF),
                  Color(0xFF0000FF),
                  Color(0xFFFF00FF),
                  Color(0xFFFF0000),
                ],
              ),
            ),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,
            thumbColor: HSVColor.fromAHSV(1, value, 1, 1).toColor(),
            trackHeight: AppSpacing.md,
          ),
          child: Slider(
            value: value,
            max: 360,
            label: 'Tono ${value.round()}°',
            semanticFormatterCallback: (value) =>
                'Tono ${value.round()} grados',
            onChanged: onChanged,
          ),
        ),
      ],
    ),
  );
}
