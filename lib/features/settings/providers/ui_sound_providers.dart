import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../repositories/ui_sound_repository.dart';
import '../../../services/device_ui_sound_service.dart';

final uiSoundRepositoryProvider = Provider((ref) {
  final service = DeviceUiSoundService();
  ref.onDispose(() => unawaited(service.dispose()));
  return UiSoundRepository(service);
});

class UiSoundState {
  const UiSoundState({
    this.enabled = false,
    this.loading = true,
    this.failed = false,
    this.volumePercent = 75,
  });
  final bool enabled, loading, failed;
  final int volumePercent;
}

final uiSoundProvider = NotifierProvider<UiSoundController, UiSoundState>(
  UiSoundController.new,
);

class UiSoundController extends Notifier<UiSoundState> {
  @override
  UiSoundState build() {
    scheduleMicrotask(() async {
      try {
        final settings = await ref.read(uiSoundRepositoryProvider).restore();
        if (ref.mounted) {
          state = UiSoundState(
            enabled: settings.enabled,
            volumePercent: settings.volumePercent,
            loading: false,
          );
        }
      } catch (_) {
        if (ref.mounted) {
          state = const UiSoundState(loading: false, failed: true);
        }
      }
    });
    return const UiSoundState();
  }

  Future<void> select(bool value) async {
    state = UiSoundState(
      enabled: value,
      volumePercent: state.volumePercent,
      loading: true,
    );
    try {
      await ref.read(uiSoundRepositoryProvider).select(value);
      if (ref.mounted) {
        state = UiSoundState(
          enabled: value,
          volumePercent: state.volumePercent,
          loading: false,
        );
      }
    } catch (_) {
      if (ref.mounted) {
        state = UiSoundState(
          enabled: value,
          volumePercent: state.volumePercent,
          loading: false,
          failed: true,
        );
      }
    }
  }

  void previewVolume(int value) {
    if (state.loading) return;
    ref.read(uiSoundRepositoryProvider).previewVolume(value);
    state = UiSoundState(
      enabled: state.enabled,
      volumePercent: value,
      loading: false,
    );
  }

  Future<void> saveVolume(int value) async {
    if (state.loading) return;
    state = UiSoundState(enabled: state.enabled, volumePercent: value);
    try {
      await ref.read(uiSoundRepositoryProvider).saveVolume(value);
      if (ref.mounted) {
        state = UiSoundState(
          enabled: state.enabled,
          volumePercent: value,
          loading: false,
        );
      }
    } catch (_) {
      if (ref.mounted) {
        state = UiSoundState(
          enabled: state.enabled,
          volumePercent: value,
          loading: false,
          failed: true,
        );
      }
    }
  }
}
