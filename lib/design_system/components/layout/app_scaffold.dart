import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_gradients.dart';
import '../navigation/app_navigation_host.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigation,
    this.floatingAction,
    this.scroll = true,
    this.padding = const EdgeInsets.all(AppSpacing.page),
    this.maxWidth = AppSpacing.contentMax,
  });
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigation;
  final Widget? floatingAction;
  final bool scroll;
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  @override
  Widget build(BuildContext context) {
    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: Padding(
            padding: floatingAction == null
                ? EdgeInsets.zero
                : const EdgeInsets.only(bottom: AppSpacing.floatingClearance),
            child: child,
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: appBar,
      bottomNavigationBar: AppNavigationHost.contains(context)
          ? null
          : bottomNavigation,
      floatingActionButton: floatingAction,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppGradients.canvas(context)),
        child: SafeArea(
          child: scroll ? SingleChildScrollView(child: content) : content,
        ),
      ),
    );
  }
}
