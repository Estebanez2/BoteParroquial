import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'motion_lab_catalog.dart';

/// Experimental effects stay here; none changes the app's route theme.
abstract final class MotionLabTransitions {
  static PageRoute<void> route({
    required LabPageEffect effect,
    required Widget child,
    required Duration duration,
    bool reduced = false,
    ValueListenable<LabPageEffect>? outgoingEffect,
  }) {
    late final PageRouteBuilder<void> route;
    route = PageRouteBuilder<void>(
      settings: RouteSettings(name: '/motion-lab/${effect.id}'),
      transitionDuration: reduced || effect == LabPageEffect.none
          ? Duration.zero
          : duration,
      reverseTransitionDuration: reduced || effect == LabPageEffect.none
          ? Duration.zero
          : duration,
      pageBuilder: (_, _, _) => child,
      transitionsBuilder: (context, animation, secondary, child) {
        if (reduced || MediaQuery.disableAnimationsOf(context)) return child;
        if (outgoingEffect != null) {
          return ValueListenableBuilder<LabPageEffect>(
            valueListenable: outgoingEffect,
            child: child,
            builder: (context, value, child) =>
                build(value, route, context, animation, secondary, child!),
          );
        }
        return build(effect, route, context, animation, secondary, child);
      },
    );
    return route;
  }

  static Widget build(
    LabPageEffect effect,
    PageRoute<void> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    if (effect == LabPageEffect.none) return child;
    if (effect == LabPageEffect.ios) {
      return const CupertinoPageTransitionsBuilder().buildTransitions(
        route,
        context,
        animation,
        secondary,
        child,
      );
    }
    if (effect == LabPageEffect.androidZoom) {
      return const ZoomPageTransitionsBuilder().buildTransitions(
        route,
        context,
        animation,
        secondary,
        child,
      );
    }
    if (effect == LabPageEffect.androidForward) {
      return const FadeForwardsPageTransitionsBuilder().buildTransitions(
        route,
        context,
        animation,
        secondary,
        child,
      );
    }
    final progress = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    final content = RepaintBoundary(child: child);
    Widget slide(Offset from, {bool fade = false}) {
      final result = SlideTransition(
        position: progress.drive(Tween(begin: from, end: Offset.zero)),
        child: content,
      );
      return fade ? FadeTransition(opacity: progress, child: result) : result;
    }

    Widget scale(double from, {Animation<double>? value}) => FadeTransition(
      opacity: value ?? progress,
      child: ScaleTransition(
        scale: (value ?? progress).drive(Tween(begin: from, end: 1)),
        child: content,
      ),
    );
    return switch (effect) {
      LabPageEffect.fade => FadeTransition(opacity: progress, child: content),
      LabPageEffect.right => slide(const Offset(1, 0)),
      LabPageEffect.left => slide(const Offset(-1, 0)),
      LabPageEffect.up => slide(const Offset(0, 1)),
      LabPageEffect.down => slide(const Offset(0, -1)),
      LabPageEffect.shortSlide => slide(const Offset(.12, 0), fade: true),
      LabPageEffect.sharedX || LabPageEffect.sharedY => SlideTransition(
        position: secondary.drive(
          Tween(
            begin: Offset.zero,
            end: effect == LabPageEffect.sharedX
                ? const Offset(-.18, 0)
                : const Offset(0, -.18),
          ),
        ),
        child: slide(
          effect == LabPageEffect.sharedX
              ? const Offset(.18, 0)
              : const Offset(0, .18),
          fade: true,
        ),
      ),
      LabPageEffect.zoom => scale(.8),
      LabPageEffect.deepZoom => scale(.5),
      LabPageEffect.zoomOut => scale(1.25),
      LabPageEffect.fadeThrough => FadeTransition(
        opacity: secondary.drive(
          Tween<double>(
            begin: 1,
            end: 0,
          ).chain(CurveTween(curve: const Interval(0, .3))),
        ),
        child: scale(
          .92,
          value: animation.drive(
            CurveTween(
              curve: const Interval(.3, 1, curve: Curves.easeOutCubic),
            ),
          ),
        ),
      ),
      LabPageEffect.turn => RotationTransition(
        turns: progress.drive(Tween(begin: -.06, end: 0)),
        child: scale(.8),
      ),
      LabPageEffect.flipX || LabPageEffect.flipY => AnimatedBuilder(
        animation: progress,
        child: content,
        builder: (_, child) {
          final transform = Matrix4.identity()..setEntry(3, 2, .001);
          final angle = (1 - progress.value) * math.pi / 2;
          if (effect == LabPageEffect.flipX) {
            transform.rotateY(angle);
          } else {
            transform.rotateX(-angle);
          }
          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: child,
          );
        },
      ),
      LabPageEffect.circle => ClipPath(
        clipper: _CircleReveal(progress),
        child: content,
      ),
      LabPageEffect.wipeX || LabPageEffect.wipeY => ClipRect(
        child: Align(
          alignment: effect == LabPageEffect.wipeX
              ? Alignment.centerLeft
              : Alignment.bottomCenter,
          child: AnimatedBuilder(
            animation: progress,
            child: content,
            builder: (_, child) => ClipRect(
              clipper: _WipeReveal(
                progress.value,
                effect == LabPageEffect.wipeX,
              ),
              child: child,
            ),
          ),
        ),
      ),
      LabPageEffect.diagonal => slide(const Offset(.6, .6), fade: true),
      LabPageEffect.spring => SlideTransition(
        position: animation.drive(
          Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutBack)),
        ),
        child: content,
      ),
      _ => content,
    };
  }
}

class _CircleReveal extends CustomClipper<Path> {
  _CircleReveal(this.progress) : super(reclip: progress);
  final Animation<double> progress;
  @override
  Path getClip(Size size) => Path()
    ..addOval(
      Rect.fromCircle(
        center: size.center(Offset.zero),
        radius:
            math.sqrt(size.width * size.width + size.height * size.height) *
            .5 *
            progress.value,
      ),
    );
  @override
  bool shouldReclip(_CircleReveal oldClipper) =>
      oldClipper.progress != progress;
}

class _WipeReveal extends CustomClipper<Rect> {
  const _WipeReveal(this.value, this.horizontal);
  final double value;
  final bool horizontal;
  @override
  Rect getClip(Size size) => horizontal
      ? Rect.fromLTWH(0, 0, size.width * value, size.height)
      : Rect.fromLTWH(
          0,
          size.height * (1 - value),
          size.width,
          size.height * value,
        );
  @override
  bool shouldReclip(_WipeReveal oldClipper) =>
      oldClipper.value != value || oldClipper.horizontal != horizontal;
}
