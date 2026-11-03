import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../design_system.dart';
import 'motion_lab_catalog.dart';

/// Temporary button renderer, intentionally independent of global press motion.
class MotionLabButton extends StatefulWidget {
  const MotionLabButton({
    super.key,
    required this.effect,
    required this.duration,
    required this.onTested,
  });
  final LabButtonEffect effect;
  final Duration duration;
  final VoidCallback onTested;
  @override
  State<MotionLabButton> createState() => _MotionLabButtonState();
}

class _MotionLabButtonState extends State<MotionLabButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _busy = false;

  Future<void> _play() async {
    if (_busy) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.onTested();
      return;
    }
    _busy = true;
    _controller.duration = widget.duration;
    try {
      await _controller.forward(from: 0).orCancel;
      if (mounted) widget.onTested();
    } on TickerCanceled {
      // Leaving the temporary laboratory cancels the effect.
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final type = AppTypography.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final reduced = MediaQuery.disableAnimationsOf(context);
        final t = reduced ? 0.0 : _controller.value;
        final wave = math.sin(math.pi * t);
        final effect = widget.effect;
        var scaleX = 1.0, scaleY = 1.0, rotation = 0.0;
        var offset = Offset.zero;
        switch (effect) {
          case LabButtonEffect.press:
            scaleX = scaleY = 1 - .08 * wave;
          case LabButtonEffect.pop:
            scaleX = scaleY = 1 + .09 * wave;
          case LabButtonEffect.bounce:
            offset = Offset(
              0,
              -AppSpacing.lg * wave * (1 + .25 * math.sin(4 * math.pi * t)),
            );
          case LabButtonEffect.shake:
            offset = Offset(
              AppSpacing.sm * math.sin(8 * math.pi * t) * (1 - t),
              0,
            );
          case LabButtonEffect.tilt:
            rotation = .09 * math.sin(4 * math.pi * t) * (1 - t);
          case LabButtonEffect.squish:
            scaleX = 1 + .10 * wave;
            scaleY = 1 - .14 * wave;
          case LabButtonEffect.lift:
            offset = Offset(0, -AppSpacing.sm * wave);
          default:
            break;
        }
        final icon = Icon(
          effect == LabButtonEffect.iconSwap && t > .15 && t < .8
              ? Icons.check_rounded
              : Icons.touch_app_outlined,
          color: c.onPrimary,
          key: ValueKey(
            effect == LabButtonEffect.iconSwap && t > .15 && t < .8,
          ),
        );
        final content = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            effect == LabButtonEffect.spin
                ? Transform.rotate(angle: t * 2 * math.pi, child: icon)
                : effect == LabButtonEffect.iconSwap
                ? AnimatedSwitcher(
                    duration: reduced ? Duration.zero : widget.duration ~/ 4,
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: icon,
                  )
                : icon,
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'Probar ${effect.id}',
                style: type.labelLarge.copyWith(color: c.onPrimary),
              ),
            ),
          ],
        );
        final active = !reduced && _controller.isAnimating;
        final button = Material(
          color: c.primary,
          borderRadius: AppRadius.control,
          child: InkWell(
            onTap: _play,
            borderRadius: AppRadius.control,
            child: ClipRRect(
              borderRadius: AppRadius.control,
              child: Stack(
                children: [
                  if (effect == LabButtonEffect.shine && active)
                    Positioned.fill(
                      child: FractionalTranslation(
                        translation: Offset(-1.4 + 2.8 * t, 0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                c.onPrimary.withValues(alpha: 0),
                                c.onPrimary.withValues(alpha: .55),
                                c.onPrimary.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (effect == LabButtonEffect.fill && active)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: wave,
                          child: ColoredBox(
                            color: c.onPrimary.withValues(alpha: .25),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: content,
                  ),
                ],
              ),
            ),
          ),
        );
        return Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: rotation,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (effect == LabButtonEffect.ring && active)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Transform.scale(
                          scale: 1 + .2 * t,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.control,
                              border: Border.all(
                                color: c.primary.withValues(alpha: 1 - t),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  button,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
