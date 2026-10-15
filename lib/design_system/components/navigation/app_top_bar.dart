import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.editorial = false,
  });
  final bool editorial;
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.topBarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: editorial ? AppTypography.of(context).editorialTitle : null,
    ),
    leadingWidth: leading == null ? null : AppSpacing.topBarHeight,
    leading: leading == null
        ? null
        : Padding(padding: const EdgeInsets.all(AppSpacing.md), child: leading),
    actions: [
      ...?actions,
      const SizedBox(width: AppSpacing.sm),
    ],
    toolbarHeight: preferredSize.height,
    titleSpacing: leading == null ? AppSpacing.page : 0,
  );
}
