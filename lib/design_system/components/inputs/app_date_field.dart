import 'package:flutter/material.dart';
import 'app_text_field.dart';

class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.error,
  });
  final String label;
  final DateTime? value, firstDate, lastDate;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;
  final String? error;
  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? ''
        : MaterialLocalizations.of(context).formatMediumDate(value!);
    Future<void> selectDate() async {
      final first = firstDate ?? DateTime(2000);
      final last = lastDate ?? DateTime(2100);
      final initial = value ?? DateTime.now();
      final chosen = await showDatePicker(
        context: context,
        firstDate: first,
        lastDate: last,
        initialDate: initial.isBefore(first)
            ? first
            : initial.isAfter(last)
            ? last
            : initial,
        helpText: label,
        cancelText: 'Cancelar',
        confirmText: 'Seleccionar',
        initialEntryMode: DatePickerEntryMode.calendarOnly,
      );
      if (chosen != null && context.mounted) onChanged(chosen);
    }

    return AppTextField(
      key: ValueKey(text),
      label: label,
      initialValue: text,
      hint: 'Selecciona una fecha',
      readOnly: true,
      enabled: enabled,
      error: error,
      icon: Icons.calendar_today_outlined,
      onTap: enabled ? selectDate : null,
    );
  }
}
