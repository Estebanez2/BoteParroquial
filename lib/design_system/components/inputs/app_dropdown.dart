import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.hint,
    this.error,
    this.enabled = true,
  });
  final String label;
  final Map<T, String> options;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? hint, error;
  final bool enabled;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    key: ValueKey(value),
    initialValue: value,
    isExpanded: true,
    style: AppTypography.of(context).bodyLarge,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: error,
    ),
    items: options.entries
        .map(
          (entry) =>
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
        )
        .toList(),
    onChanged: enabled ? onChanged : null,
    borderRadius:
        Theme.of(context).inputDecorationTheme.border is OutlineInputBorder
        ? (Theme.of(context).inputDecorationTheme.border! as OutlineInputBorder)
              .borderRadius
        : null,
  );
}
