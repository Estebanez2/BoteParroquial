import 'package:flutter/material.dart';
import '../cards/app_card.dart';
import '../buttons/app_icon_button.dart';
import '../../theme/app_spacing.dart';
import 'app_toggle_tile.dart';
import 'app_volume_slider.dart';

class AppSoundSettingsPanel extends StatelessWidget {
  const AppSoundSettingsPanel({
    super.key,
    required this.enabled,
    required this.volume,
    required this.onEnabled,
    required this.onVolume,
    required this.onVolumeEnd,
    this.onPreview,
  });
  final bool enabled;
  final int volume;
  final ValueChanged<bool>? onEnabled;
  final ValueChanged<int>? onVolume, onVolumeEnd;
  final VoidCallback? onPreview;
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: AppToggleTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sonidos'),
                value: enabled,
                onChanged: onEnabled,
              ),
            ),
            AppIconButton(
              icon: Icons.volume_up_outlined,
              label: 'Probar sonido',
              variant: AppIconButtonVariant.ghost,
              onPressed: onPreview,
            ),
          ],
        ),
        AppVolumeSlider(
          value: volume,
          compact: true,
          onChanged: onVolume,
          onChangeEnd: onVolumeEnd,
        ),
      ],
    ),
  );
}
