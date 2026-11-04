import '../models/ui_sound.dart';
import '../models/ui_sound_settings.dart';

abstract interface class UiSoundService {
  Future<UiSoundSettings> loadSettings();
  Future<void> saveSettings(UiSoundSettings value);
  Future<void> play(UiSound sound, {required double volume});
  Future<void> stop();
  Future<void> dispose();
}
