import 'package:flutter/widgets.dart';

/// Ephemeral visual order shared by entering and departing section routes.
class AppSectionMotionScope extends InheritedWidget {
  const AppSectionMotionScope({
    super.key,
    required this.fromIndex,
    required this.toIndex,
    required super.child,
  });
  final int fromIndex, toIndex;
  int get direction => toIndex.compareTo(fromIndex);
  static AppSectionMotionScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSectionMotionScope>();
  @override
  bool updateShouldNotify(AppSectionMotionScope oldWidget) =>
      fromIndex != oldWidget.fromIndex || toIndex != oldWidget.toIndex;
}
