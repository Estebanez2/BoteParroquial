import 'package:flutter/material.dart';

/// Keeps one bar outside a section Navigator; nested AppScaffolds omit theirs.
class AppNavigationHost extends StatelessWidget {
  const AppNavigationHost({
    super.key,
    required this.child,
    required this.navigation,
  });
  final Widget child;
  final Widget navigation;

  static bool contains(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_NavigationScope>() != null;

  /// Outside the section Navigator, still inside this app/copy's provider scope.
  static BuildContext modalContextOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_NavigationScope>()
          ?.modalContext ??
      context;

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: navigation,
    body: _NavigationScope(modalContext: context, child: child),
  );
}

class _NavigationScope extends InheritedWidget {
  const _NavigationScope({required this.modalContext, required super.child});
  final BuildContext modalContext;
  @override
  bool updateShouldNotify(_NavigationScope oldWidget) => false;
}
