import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../navigation/app_menu_row.dart';
import 'app_icon_button.dart';

class AppActionMenu<T> extends StatefulWidget {
  const AppActionMenu({
    super.key,
    required this.label,
    required this.items,
    required this.onSelected,
    this.enabled = true,
  });
  final String label;
  final Map<T, String> items;
  final ValueChanged<T> onSelected;
  final bool enabled;
  @override
  State<AppActionMenu<T>> createState() => _AppActionMenuState<T>();
}

class _AppActionMenuState<T> extends State<AppActionMenu<T>> {
  final _menu = GlobalKey<PopupMenuButtonState<T>>();
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      key: _menu,
      // The child already owns its tooltip and accessible label.
      tooltip: '',
      enabled: widget.enabled,
      onSelected: widget.onSelected,
      offset: const Offset(0, AppSpacing.sm),
      child: AppIconButton(
        icon: Icons.more_vert_rounded,
        label: widget.label,
        onPressed: widget.enabled
            ? () => _menu.currentState?.showButtonMenu()
            : null,
      ),
      itemBuilder: (context) => [
        for (final entry in widget.items.entries)
          PopupMenuItem<T>(
            value: entry.key,
            child: AppMenuRow(label: entry.value),
          ),
      ],
    );
  }
}
