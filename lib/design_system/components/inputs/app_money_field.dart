import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'app_text_field.dart';

/// Decimal input without thousands separators. Integer arithmetic only.
int? parseMoneyCents(String text) {
  if (!RegExp(r'^\d{1,12}([,.]\d{0,2})?$').hasMatch(text)) return null;
  final parts = text.replaceAll('.', ',').split(',');
  final whole = int.tryParse(parts.first);
  if (whole == null) return null;
  final fraction = parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0'));
  return whole * 100 + fraction;
}

class AppMoneyField extends StatelessWidget {
  const AppMoneyField({
    super.key,
    this.label = 'Cantidad',
    required this.currency,
    this.controller,
    this.onChangedCents,
    this.enabled = true,
    this.error,
  });
  final String label, currency;
  final TextEditingController? controller;
  final ValueChanged<int?>? onChangedCents;
  final bool enabled;
  final String? error;
  @override
  Widget build(BuildContext context) => AppTextField(
    label: label,
    hint: '0,00',
    prominent: true,
    controller: controller,
    enabled: enabled,
    error: error,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [
      TextInputFormatter.withFunction(
        (oldValue, newValue) =>
            RegExp(r'^\d{0,12}([,.]\d{0,2})?$').hasMatch(newValue.text)
            ? newValue
            : oldValue,
      ),
    ],
    onChanged: (text) => onChangedCents?.call(parseMoneyCents(text)),
    validator: (text) => text == null || parseMoneyCents(text) == null
        ? 'Introduce una cantidad válida.'
        : null,
    suffix: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(
        currency,
        style: TextStyle(color: AppColors.of(context).textSecondary),
      ),
    ),
  );
}
