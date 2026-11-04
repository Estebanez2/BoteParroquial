import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../feedback/app_sound_scope.dart';

class AppVolumeSlider extends StatelessWidget {
  const AppVolumeSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
    this.compact = false,
  });
  final int value;
  final bool compact;
  final ValueChanged<int>? onChanged, onChangeEnd;
  @override
  Widget build(BuildContext context) {
    final slider = Slider(
      value: value.toDouble(),
      min: 0,
      max: 100,
      divisions: 100,
      label: '$value %',
      semanticFormatterCallback: (value) => '${value.round()} por ciento',
      onChanged: onChanged == null
          ? null
          : (value) => onChanged!(value.round()),
      onChangeEnd: onChangeEnd == null
          ? null
          : (value) {
              onChangeEnd!(value.round());
              AppSoundScope.emit(context, UiSound.tap);
            },
    );
    if (compact) {
      return Row(
        children: [
          const Icon(Icons.volume_down_outlined),
          Expanded(child: slider),
          Text('$value %', style: AppTypography.of(context).labelSmall),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Volumen: $value %', style: AppTypography.of(context).bodyMedium),
        slider,
      ],
    );
  }
}
