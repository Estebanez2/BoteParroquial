import 'package:flutter/material.dart';
import '../feedback/app_sound_scope.dart';

/// Shared selection feedback, keeping native semantics and disabled behavior.
class AppToggleTile extends StatelessWidget {
  const AppToggleTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.checkbox = false,
    this.contentPadding = EdgeInsets.zero,
  });
  final Widget title;
  final Widget? subtitle;
  final bool value, checkbox;
  final ValueChanged<bool>? onChanged;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    void changed(bool value) {
      AppSoundScope.emit(context, UiSound.tap);
      onChanged?.call(value);
    }

    return checkbox
        ? CheckboxListTile(
            title: title,
            subtitle: subtitle,
            value: value,
            contentPadding: contentPadding,
            onChanged: onChanged == null
                ? null
                : (value) {
                    if (value != null) changed(value);
                  },
          )
        : SwitchListTile.adaptive(
            title: title,
            subtitle: subtitle,
            value: value,
            contentPadding: contentPadding,
            onChanged: onChanged == null ? null : changed,
          );
  }
}
