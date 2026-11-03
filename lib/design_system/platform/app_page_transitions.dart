import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import 'app_section_motion_scope.dart';

enum AppPageMotion { standard, group, section, form }

/// Carries visual intent without route names or product rules in the library.
class AppMotionPage<T> extends MaterialPage<T> {
  const AppMotionPage({
    required super.child,
    this.motion = AppPageMotion.standard,
    this.sectionIndex,
    this.origin,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });
  final AppPageMotion motion;
  final int? sectionIndex;
  final Rect? origin;
}

abstract final class AppPageTransitions {
  static PageRoute<void> formRoute(BuildContext context, Widget child) =>
      PageRouteBuilder<void>(
        transitionDuration: AppMotion.duration(context, AppMotion.durationPage),
        reverseTransitionDuration: AppMotion.duration(
          context,
          AppMotion.durationPage,
        ),
        pageBuilder: (_, _, _) => child,
        transitionsBuilder: form,
      );

  static Widget build(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child, {
    AppPageMotion motion = AppPageMotion.standard,
    int? sectionIndex,
    Rect? origin,
  }) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    Animation<double> eased(Animation<double> source) => source.drive(
      CurveTween(
        curve: source.status == AnimationStatus.reverse
            ? Curves.easeInCubic
            : AppMotion.curveStandard,
      ),
    );
    final progress = eased(animation);
    final content = RepaintBoundary(child: child);
    if (motion == AppPageMotion.group && origin != null && !origin.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: progress,
          child: content,
          builder: (context, child) {
            final full = Offset.zero & constraints.biggest;
            final rect = Rect.lerp(origin, full, progress.value)!;
            return Transform(
              alignment: Alignment.topLeft,
              transform: Matrix4.identity()
                ..translateByDouble(rect.left, rect.top, 0, 1)
                ..scaleByDouble(
                  rect.width / full.width,
                  rect.height / full.height,
                  1,
                  1,
                ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  AppRadius.large * (1 - progress.value),
                ),
                child: child,
              ),
            );
          },
        ),
      );
    }
    if (motion == AppPageMotion.section && sectionIndex != null) {
      final order = AppSectionMotionScope.maybeOf(context);
      if (order != null && order.direction != 0) {
        final sign = order.direction.toDouble();
        if (sectionIndex == order.fromIndex) {
          if (animation.status == AnimationStatus.reverse) {
            return SlideTransition(
              position: progress.drive(
                Tween(begin: Offset(-sign, 0), end: Offset.zero),
              ),
              child: content,
            );
          }
          return SlideTransition(
            position: eased(
              secondaryAnimation,
            ).drive(Tween(begin: Offset.zero, end: Offset(-sign, 0))),
            child: content,
          );
        }
        if (sectionIndex == order.toIndex) {
          if (secondaryAnimation.status == AnimationStatus.reverse) {
            return SlideTransition(
              position: eased(
                secondaryAnimation,
              ).drive(Tween(begin: Offset.zero, end: Offset(sign, 0))),
              child: content,
            );
          }
          return SlideTransition(
            position: progress.drive(
              Tween(begin: Offset(sign, 0), end: Offset.zero),
            ),
            child: content,
          );
        }
        return content;
      }
    }
    return SlideTransition(
      position: progress.drive(
        Tween(
          begin: motion == AppPageMotion.form
              ? const Offset(0, 1)
              : const Offset(1, 0),
          end: Offset.zero,
        ),
      ),
      child: content,
    );
  }

  static Widget form(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => build(
    context,
    animation,
    secondaryAnimation,
    child,
    motion: AppPageMotion.form,
  );
}

class AppContextPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppContextPageTransitionsBuilder();
  @override
  Duration get transitionDuration => AppMotion.durationPage;
  @override
  Duration get reverseTransitionDuration => AppMotion.durationPage;
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => AppPageTransitions.build(
    context,
    animation,
    secondaryAnimation,
    child,
    motion: route.settings is AppMotionPage
        ? (route.settings as AppMotionPage).motion
        : AppPageMotion.standard,
    sectionIndex: route.settings is AppMotionPage
        ? (route.settings as AppMotionPage).sectionIndex
        : null,
    origin: route.settings is AppMotionPage
        ? (route.settings as AppMotionPage).origin
        : null,
  );
}

/// Keep Apple's native back gesture while respecting reduced motion.
class AppCupertinoPageTransitionsBuilder
    extends CupertinoPageTransitionsBuilder {
  const AppCupertinoPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MediaQuery.disableAnimationsOf(context)
      ? child
      : route.settings is AppMotionPage &&
            (route.settings as AppMotionPage).motion != AppPageMotion.standard
      ? const AppContextPageTransitionsBuilder().buildTransitions(
          route,
          context,
          animation,
          secondaryAnimation,
          child,
        )
      : super.buildTransitions(
          route,
          context,
          animation,
          secondaryAnimation,
          child,
        );
}
