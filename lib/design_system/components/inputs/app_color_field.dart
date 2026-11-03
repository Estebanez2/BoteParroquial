import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../buttons/app_button.dart';
import '../layout/app_bottom_sheet.dart';
import 'app_text_field.dart';
import 'app_color_plane.dart';

/// Reusable local color selection. Returns a draft; never persists preferences.
class AppColorField extends StatelessWidget {
  const AppColorField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  final String label;
  final Color value;
  final ValueChanged<Color> onChanged;
  final bool enabled;
  static String hex(Color color) =>
      color.toARGB32().toRadixString(16).substring(2).toUpperCase();
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: !enabled
        ? null
        : () async {
            final color = await AppBottomSheet.show<Color>(
              context,
              title: label,
              builder: (_) => _ColorPicker(initial: value),
            );
            if (context.mounted && color != null) onChanged(color);
          },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: AppSpacing.avatarMedium,
            height: AppSpacing.avatarMedium,
            decoration: BoxDecoration(
              color: value,
              borderRadius: AppRadius.control,
              border: Border.all(color: AppColors.of(context).outline),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.of(context).labelLarge),
                Text(
                  '#${hex(value)}',
                  style: AppTypography.of(context).bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.colorize_rounded),
        ],
      ),
    ),
  );
}

class _ColorPicker extends StatefulWidget {
  const _ColorPicker({required this.initial});
  final Color initial;
  @override
  State<_ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<_ColorPicker> {
  late HSVColor _color = HSVColor.fromColor(widget.initial);
  late final _hex = TextEditingController(
    text: AppColorField.hex(widget.initial),
  );
  bool _valid = true;
  void _set(HSVColor color) => setState(() {
    _color = color;
    _valid = true;
    _hex.text = AppColorField.hex(color.toColor());
  });
  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        height: AppSpacing.avatarLarge,
        decoration: BoxDecoration(
          color: _color.toColor(),
          borderRadius: AppRadius.control,
          border: Border.all(color: AppColors.of(context).outline),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(
        'Mueve el círculo hasta encontrar tu color.',
        style: AppTypography.of(context).labelLarge,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'A la izquierda, más blanco; abajo, más oscuro. La barra arcoíris cambia el color de base.',
        style: AppTypography.of(context).bodySmall,
      ),
      const SizedBox(height: AppSpacing.md),
      AppColorPlane(value: _color, onChanged: _set),
      const SizedBox(height: AppSpacing.sm),
      AppHueSlider(
        value: _color.hue,
        onChanged: (hue) => _set(_color.withHue(hue)),
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        label: 'Código hexadecimal',
        controller: _hex,
        hint: '2459C4',
        error: _valid ? null : 'Escribe seis cifras de 0–9 o A–F.',
        onChanged: (raw) {
          final text = raw.trim().replaceFirst('#', '');
          setState(() {
            _valid = RegExp(r'^[a-fA-F0-9]{6}$').hasMatch(text);
            if (_valid) {
              _color = HSVColor.fromColor(
                Color(0xFF000000 | int.parse(text, radix: 16)),
              );
            }
          });
        },
      ),
      const SizedBox(height: AppSpacing.md),
      AppButton(
        label: 'Usar este color',
        onPressed: _valid
            ? () => Navigator.pop(context, _color.toColor())
            : null,
      ),
    ],
  );
}
