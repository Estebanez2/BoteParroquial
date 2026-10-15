import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigation,
    this.scroll = true,
    this.padding = const EdgeInsets.all(AppSpacing.page),
    this.maxWidth = AppSpacing.contentMax,
  });
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigation;
  final bool scroll;
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  @override
  Widget build(BuildContext context) {
    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
    return Scaffold(
      appBar: appBar,
      bottomNavigationBar: bottomNavigation,
      body: SafeArea(
        child: scroll ? SingleChildScrollView(child: content) : content,
      ),
    );
  }
}
