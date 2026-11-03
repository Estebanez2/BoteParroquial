import 'package:flutter/widgets.dart';

/// Visual lifetime only. The feature owns the access decision and opaque key.
class AppSectionRenderScope extends InheritedWidget {
  const AppSectionRenderScope({
    super.key,
    required this.accessKey,
    required this.canFreeze,
    required this.outerAnimations,
    required super.child,
  });
  final Object accessKey;
  final bool canFreeze;
  final List<Animation<double>> outerAnimations;
  static AppSectionRenderScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSectionRenderScope>();
  @override
  bool updateShouldNotify(AppSectionRenderScope oldWidget) =>
      accessKey != oldWidget.accessKey ||
      canFreeze != oldWidget.canFreeze ||
      !_sameAnimations(outerAnimations, oldWidget.outerAnimations);

  static bool _sameAnimations(
    List<Animation<double>> a,
    List<Animation<double>> b,
  ) =>
      a.length == b.length &&
      List.generate(
        a.length,
        (i) => identical(a[i], b[i]),
      ).every((same) => same);
}
