import '../models/ui_sound.dart';
import '../models/ui_sound_settings.dart';
import '../services/ui_sound_service.dart';

class UiSoundRepository {
  UiSoundRepository(this.service);
  final UiSoundService service;

  bool active = true;
  UiSoundSettings settings = const UiSoundSettings(enabled: false);

  Future<UiSoundSettings> restore() async =>
      settings = await service.loadSettings();
  Future<void> select(bool value) async {
    settings = settings.copyWith(enabled: value);
    if (!value) await service.stop();
    await service.saveSettings(settings);
  }

  void previewVolume(int value) {
    if (value < 0 || value > 100) throw ArgumentError.value(value);
    settings = settings.copyWith(volumePercent: value);
  }

  Future<void> saveVolume(int value) async {
    previewVolume(value);
    if (value == 0) await service.stop();
    await service.saveSettings(settings);
  }

  Future<void> play(UiSound sound) async {
    if (!settings.enabled || !active || settings.volumePercent == 0) return;
    try {
      await service.play(
        sound,
        volume:
            settings.volumePercent / 100 * (sound == UiSound.typing ? .45 : 1),
      );
    } catch (_) {}
  }
}
