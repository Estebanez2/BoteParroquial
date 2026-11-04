import 'package:flutter/material.dart';
import '../feedback/app_sound_scope.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../navigation/app_menu_row.dart';

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
    onTap: enabled && onChanged != null
        ? () => AppSoundScope.emit(context, UiSound.menu)
        : null,
    itemHeight: null,
    dropdownColor: AppColors.of(context).surface,
    elevation: 8,
    icon: Icon(
      Icons.unfold_more_rounded,
      color: AppColors.of(context).secondary,
    ),
    style: AppTypography.of(context).bodyLarge,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: error,
    ),
    items: options.entries
        .map(
          (entry) => DropdownMenuItem(
            value: entry.key,
            child: AppMenuRow(
              label: entry.value,
              icon: Icons.radio_button_unchecked_rounded,
              selected: entry.key == value,
            ),
          ),
        )
        .toList(),
    onChanged: enabled && onChanged != null
        ? (value) {
            AppSoundScope.emit(context, UiSound.menu);
            onChanged!(value);
          }
        : null,
    selectedItemBuilder: (context) => options.values
        .map(
          (label) => Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.of(context).bodyLarge,
            ),
          ),
        )
        .toList(),
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    borderRadius: AppRadius.card,
  );
}
