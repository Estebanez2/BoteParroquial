import 'package:flutter/material.dart';
import 'app_menu_row.dart';
import '../buttons/app_button.dart';
import '../feedback/app_sound_scope.dart';

class AppFloatingActions<T> extends StatefulWidget {
  const AppFloatingActions({
    super.key,
    required this.label,
    required this.items,
    required this.onSelected,
    this.icons = const {},
  });
  final String label;
  final Map<T, String> items;
  final ValueChanged<T> onSelected;
  final Map<T, IconData> icons;
  @override
  State<AppFloatingActions<T>> createState() => _AppFloatingActionsState<T>();
}

class _AppFloatingActionsState<T> extends State<AppFloatingActions<T>> {
  final _menu = GlobalKey<PopupMenuButtonState<T>>();
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      key: _menu,
      tooltip: widget.label,
      onSelected: (value) {
        AppSoundScope.emit(context, UiSound.menu);
        widget.onSelected(value);
      },
      itemBuilder: (_) => [
        for (final item in widget.items.entries)
          PopupMenuItem<T>(
            value: item.key,
            child: AppMenuRow(
              label: item.value,
              icon: widget.icons[item.key] ?? Icons.add_rounded,
            ),
          ),
      ],
      child: AppButton(
        label: widget.label,
        leadingIcon: Icons.add_rounded,
        sound: UiSound.menu,
        onPressed: () => _menu.currentState?.showButtonMenu(),
      ),
    );
  }
}
