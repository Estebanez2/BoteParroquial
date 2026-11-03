import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/appearance_settings.dart';
import '../../../models/custom_palette.dart';
import '../../../repositories/appearance_repository.dart';
import '../../../services/file_appearance_service.dart';

final appearanceRepositoryProvider = Provider(
  (ref) => AppearanceRepository(FileAppearanceService()),
);
final appearanceProvider =
    NotifierProvider<AppearanceController, AppearanceState>(
      AppearanceController.new,
    );

class AppearanceState {
  const AppearanceState({
    this.settings = const AppearanceSettings(),
    this.loading = false,
    this.saveFailed = false,
  });
  final AppearanceSettings settings;
  final bool loading, saveFailed;
}

class AppearanceController extends Notifier<AppearanceState> {
  int _revision = 0;
  @override
  AppearanceState build() {
    final revision = _revision;
    scheduleMicrotask(() => _restore(revision));
    return const AppearanceState(loading: true);
  }

  Future<void> _restore(int revision) async {
    if (!ref.mounted || revision != _revision) return;
    final settings = await ref.read(appearanceRepositoryProvider).load();
    if (ref.mounted && revision == _revision) {
      state = AppearanceState(settings: settings);
    }
  }

  Future<void> select({
    AppPalette? palette,
    AppearanceMode? mode,
    AppFont? font,
  }) async {
    final settings = state.settings.copyWith(
      palette: palette,
      mode: mode,
      font: font,
      clearCustom: palette != null,
    );
    await _commit(settings);
  }

  Future<void> selectCustom(String id) async {
    if (state.settings.customPalettes.any((p) => p.id == id && p.isValid)) {
      await _commit(state.settings.copyWith(customPaletteId: id));
    }
  }

  Future<bool> saveCustom(CustomPalette palette) => _commit(
    ref.read(appearanceRepositoryProvider).withPalette(state.settings, palette),
  );
  Future<void> deleteCustom(String id) async {
    await _commit(
      ref.read(appearanceRepositoryProvider).withoutPalette(state.settings, id),
    );
  }

  Future<bool> _commit(AppearanceSettings settings) async {
    final revision = ++_revision;
    state = AppearanceState(settings: settings);
    try {
      await ref.read(appearanceRepositoryProvider).save(settings);
      return true;
    } catch (_) {
      if (ref.mounted && revision == _revision) {
        state = AppearanceState(settings: settings, saveFailed: true);
      }
      return false;
    }
  }
}
