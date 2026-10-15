import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.title, this.leading, this.actions});
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.topBarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
    title: Text(title),
    leading: leading,
    actions: [
      ...?actions,
      const SizedBox(width: AppSpacing.sm),
    ],
    toolbarHeight: preferredSize.height,
    titleSpacing: AppSpacing.page,
  );
}
