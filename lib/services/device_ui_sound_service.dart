import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ui_sound.dart';
import '../models/ui_sound_settings.dart';
import 'ui_sound_service.dart';

class DeviceUiSoundService implements UiSoundService {
  DeviceUiSoundService({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _directory;
  static const _mode = MethodChannel('boteparroquial/ui_sound');
  final _pools = <String, Future<AudioPool>>{};
  final _clicks = UiClickVariants();
  final _menus = UiClickVariants(prefix: 'click', count: 4);
  final _stops = <StopFunction>{};
  bool _disposed = false;
  int _generation = 0;

  Future<File> _file() async {
    final dir = await _directory();
    await dir.create(recursive: true);
    return File('${dir.path}/ui-sounds.json');
  }

  @override
  Future<UiSoundSettings> loadSettings() async {
    final file = await _file();
    if (await file.exists()) {
      return UiSoundSettings.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    }
    final legacy = File('${file.parent.path}/ui-sounds.txt');
    return UiSoundSettings(
      enabled:
          !await legacy.exists() ||
          (await legacy.readAsString()).trim() == 'on',
    );
  }

  Future<void> _tail = Future.value();
  @override
  Future<void> saveSettings(UiSoundSettings value) {
    final operation = _tail.then((_) async {
      final file = await _file();
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(jsonEncode(value.toJson()), flush: true);
      await temp.rename(file.path);
    });
    _tail = operation.catchError((Object _) {});
    return operation;
  }

  Future<AudioPool> _pool(String asset) => _pools.putIfAbsent(
    asset,
    () => AudioPool.create(
      source: AssetSource('sounds/$asset.wav'),
      minPlayers: 1,
      maxPlayers: 4,
      playerMode: PlayerMode.lowLatency,
      audioContext: AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      ),
    ),
  );

  @override
  Future<void> play(UiSound sound, {required double volume}) async {
    if (_disposed || volume <= 0) return;
    final generation = _generation;
    try {
      if (Platform.isAndroid &&
          await _mode.invokeMethod<bool>('canPlay') != true) {
        return;
      }
      final pool = await _pool(switch (sound) {
        UiSound.tap => _clicks.nextAsset(),
        UiSound.menu => _menus.nextAsset(),
        _ => sound.name,
      });
      if (_disposed || generation != _generation) return;
      final stop = await pool.start(volume: volume.clamp(0, 1));
      if (_disposed || generation != _generation) {
        await stop();
        return;
      }
      _stops.add(stop);
      final milliseconds = switch (sound) {
        UiSound.tap => 130,
        UiSound.menu => 130,
        UiSound.back => 240,
        UiSound.typing => 125,
        UiSound.success => 320,
        UiSound.photo => 180,
        UiSound.warning => 130,
      };
      await Future<void>.delayed(Duration(milliseconds: milliseconds));
      if (_stops.remove(stop)) await stop();
    } catch (_) {
      // Audio is optional and must never prevent a user operation.
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    final stops = _stops.toList();
    _stops.clear();
    for (final stop in stops) {
      try {
        await stop();
      } catch (_) {}
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stop();
    for (final pool in _pools.values) {
      try {
        await (await pool).dispose();
      } catch (_) {}
    }
    _pools.clear();
  }
}
