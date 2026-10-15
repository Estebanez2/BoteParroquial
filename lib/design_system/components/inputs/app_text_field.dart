import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_spacing.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.icon,
    this.error,
    this.helper,
    this.password = false,
    this.enabled = true,
    this.readOnly = false,
    this.controller,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.suffix,
    this.onTap,
    this.initialValue,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });
  final String label;
  final String? hint, error, helper, initialValue;
  final IconData? icon;
  final bool password, enabled, readOnly;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final VoidCallback? onTap;
  final AutovalidateMode autovalidateMode;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    initialValue: controller == null ? initialValue : null,
    enabled: enabled,
    readOnly: readOnly,
    obscureText: password,
    autocorrect: !password,
    enableSuggestions: !password,
    onChanged: onChanged,
    validator: validator,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    onTap: onTap,
    autovalidateMode: autovalidateMode,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: error,
      helperText: helper,
      prefixIcon: icon == null ? null : Icon(icon, size: AppSpacing.icon),
      suffixIcon: suffix,
    ),
  );
}
