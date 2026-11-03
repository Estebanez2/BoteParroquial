import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

enum AppTapEffect { shine, wave, none }

/// Visual feedback only. Validation is supplied by the form; no permission logic.
class AppControlFeedback extends StatefulWidget {
  const AppControlFeedback({
    super.key,
    required this.builder,
    required this.onActivate,
    this.enabled = true,
    this.busy = false,
    this.validate,
    this.effect = AppTapEffect.wave,
    this.radius = AppRadius.control,
    this.color,
  });
  final Widget Function(BuildContext, VoidCallback) builder;
  final VoidCallback? onActivate;
  final bool enabled, busy;
  final bool Function()? validate;
  final AppTapEffect effect;
  final BorderRadius radius;
  final Color? color;
  @override
  State<AppControlFeedback> createState() => _AppControlFeedbackState();
}

enum _FeedbackKind { tap, invalid, unavailable }

class _AppControlFeedbackState extends State<AppControlFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.durationControl,
  );
  _FeedbackKind _kind = _FeedbackKind.tap;
  bool _running = false;
  bool get _reduced => MediaQuery.disableAnimationsOf(context);

  Future<void> _activate() async {
    if (_running || widget.busy) return;
    if (!widget.enabled || widget.onActivate == null) {
      await _play(_FeedbackKind.unavailable);
      return;
    }
    if (widget.validate?.call() == false) {
      if (mounted) await _play(_FeedbackKind.invalid);
      return;
    }
    if (!mounted || !widget.enabled || widget.busy) return;
    if (_reduced || widget.effect == AppTapEffect.none) {
      widget.onActivate?.call();
      return;
    }
    _running = true;
    _kind = _FeedbackKind.tap;
    try {
      await _controller.forward(from: 0).orCancel;
      if (mounted && widget.enabled && !widget.busy) {
        final route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) return;
        if (widget.validate?.call() == false) {
          _running = false;
          await _play(_FeedbackKind.invalid);
          return;
        }
        widget.onActivate?.call();
      }
    } on TickerCanceled {
      // An access/busy change or disposal cancels the pending action.
    } finally {
      _running = false;
    }
  }

  Future<void> _play(_FeedbackKind kind) async {
    if (_running || _reduced || widget.busy) return;
    _running = true;
    _kind = kind;
    try {
      await _controller.forward(from: 0).orCancel;
    } on TickerCanceled {
      // No callback is attached to rejected attempts.
    } finally {
      _running = false;
    }
  }

  @override
  void didUpdateWidget(AppControlFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.busy || (!widget.enabled && _kind == _FeedbackKind.tap)) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.of(context).primary;
    return GestureDetector(
      excludeFromSemantics: true,
      onTap: !widget.enabled && !widget.busy ? _activate : null,
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.builder(context, _activate),
        builder: (context, child) {
          final value = _reduced ? 0.0 : _controller.value;
          final active = !_reduced && _controller.isAnimating;
          Widget content = Stack(
            clipBehavior: Clip.none,
            children: [
              child!,
              if (active &&
                  _kind == _FeedbackKind.tap &&
                  widget.effect != AppTapEffect.none)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ControlEffectPainter(
                        value,
                        widget.effect,
                        widget.radius,
                        color,
                      ),
                    ),
                  ),
                ),
            ],
          );
          if (_kind == _FeedbackKind.invalid) {
            content = Transform.translate(
              offset: Offset(
                AppSpacing.sm * math.sin(8 * math.pi * value) * (1 - value),
                0,
              ),
              child: content,
            );
          } else if (_kind == _FeedbackKind.unavailable) {
            content = Transform.rotate(
              angle: .09 * math.sin(4 * math.pi * value) * (1 - value),
              child: content,
            );
          }
          return content;
        },
      ),
    );
  }
}

class _ControlEffectPainter extends CustomPainter {
  const _ControlEffectPainter(this.value, this.effect, this.radius, this.color);
  final double value;
  final AppTapEffect effect;
  final BorderRadius radius;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (effect == AppTapEffect.wave) {
      final expansion = AppSpacing.md * value;
      canvas.drawRRect(
        radius.toRRect(rect).inflate(expansion),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 1 - value),
      );
    } else if (effect == AppTapEffect.shine) {
      canvas.save();
      canvas.clipRRect(radius.toRRect(rect));
      final x = -size.width + 2.8 * size.width * value;
      final stripe = Rect.fromLTWH(x, 0, size.width * .6, size.height);
      final path = Path()
        ..moveTo(x + size.width * .16, 0)
        ..lineTo(stripe.right, 0)
        ..lineTo(stripe.right - size.width * .16, size.height)
        ..lineTo(x, size.height)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            colors: [
              color.withValues(alpha: 0),
              color.withValues(alpha: .5),
              color.withValues(alpha: 0),
            ],
          ).createShader(stripe),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ControlEffectPainter oldDelegate) =>
      value != oldDelegate.value ||
      effect != oldDelegate.effect ||
      radius != oldDelegate.radius ||
      color != oldDelegate.color;
}
