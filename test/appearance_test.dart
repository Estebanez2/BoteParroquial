import 'dart:async';
import 'dart:io';
import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:bote_parroquial/features/settings/presentation/appearance_screen.dart';
import 'package:bote_parroquial/features/settings/providers/appearance_providers.dart';
import 'package:bote_parroquial/models/appearance_settings.dart';
import 'package:bote_parroquial/models/custom_palette.dart';
import 'package:bote_parroquial/repositories/appearance_repository.dart';
import 'package:bote_parroquial/services/file_appearance_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/memory_appearance.dart';

class _DelayedAppearance extends MemoryAppearance {
  final loaded = Completer<AppearanceSettings?>();
  @override
  Future<AppearanceSettings?> load() => loaded.future;
}

void main() {
  test('Las cinco paletas conservan contraste en ambos modos', () {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
    }

    for (final palette in AppPalette.values) {
      for (final mode in Brightness.values) {
        final c = AppColors.forPalette(palette, mode);
        for (final background in [c.background, c.surface, c.surfaceVariant]) {
          for (final text in [c.textPrimary, c.textSecondary, c.textMuted]) {
            expect(
              contrast(text, background),
              greaterThanOrEqualTo(4.5),
              reason: '${palette.name}/${mode.name}',
            );
          }
        }
        expect(contrast(c.primary, c.onPrimary), greaterThanOrEqualTo(4.5));
        expect(contrast(c.hero, c.onHero), greaterThanOrEqualTo(4.5));
        for (final pair in [
          (c.secondary, c.secondaryContainer),
          (c.tertiary, c.tertiaryContainer),
        ]) {
          expect(
            contrast(pair.$1, c.surface),
            greaterThanOrEqualTo(4.5),
            reason: '${palette.name}/${mode.name} accent',
          );
          expect(
            contrast(pair.$1, pair.$2),
            greaterThanOrEqualTo(4.5),
            reason: '${palette.name}/${mode.name} container',
          );
        }
        expect(c.secondary, isNot(c.primary));
        expect(c.tertiary, isNot(c.secondary));
      }
    }
  });

  test(
    'Preferencia local sobrevive a nueva instancia; escrituras rápidas conservan la última',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'bote-appearance-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final service = FileAppearanceService(directory: () async => directory);
      final repo = AppearanceRepository(service);
      await Future.wait([
        repo.save(
          const AppearanceSettings(
            palette: AppPalette.iris,
            mode: AppearanceMode.dark,
          ),
        ),
        repo.save(
          const AppearanceSettings(
            palette: AppPalette.coral,
            mode: AppearanceMode.light,
            font: AppFont.newsreader,
            customPalettes: [
              CustomPalette(
                id: 'local-test',
                name: 'Mi prueba',
                primaryRgb: 0xCC5511,
                secondaryRgb: 0x228899,
                tertiaryRgb: 0x6644AA,
              ),
            ],
            customPaletteId: 'local-test',
          ),
        ),
      ]);
      final restored = await AppearanceRepository(
        FileAppearanceService(directory: () async => directory),
      ).load();
      expect(restored.palette, AppPalette.coral);
      expect(restored.mode, AppearanceMode.light);
      expect(restored.font, AppFont.newsreader);
      expect(restored.customPalette!.primaryRgb, 0xCC5511);
      await File('${directory.path}/appearance.json').writeAsString('{broken');
      expect((await repo.load()).palette, AppPalette.atlantic);
      expect(
        AppearanceSettings.fromJson({
          'palette': 'future',
          'mode': 'future',
        }).mode,
        AppearanceMode.system,
      );
    },
  );

  test(
    'Una carga tardía no sobrescribe una elección nueva; error permite reintentar',
    () async {
      final storage = _DelayedAppearance();
      final container = ProviderContainer(
        overrides: [
          appearanceRepositoryProvider.overrideWithValue(
            AppearanceRepository(storage),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(appearanceProvider);
      await Future<void>.delayed(Duration.zero);
      final controller = container.read(appearanceProvider.notifier);
      await controller.select(
        palette: AppPalette.iris,
        mode: AppearanceMode.dark,
      );
      storage.loaded.complete(const AppearanceSettings());
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(appearanceProvider).settings.palette,
        AppPalette.iris,
      );
      storage.failSave = true;
      await controller.select(palette: AppPalette.graphite);
      expect(container.read(appearanceProvider).saveFailed, true);
      expect(
        container.read(appearanceProvider).settings.palette,
        AppPalette.graphite,
      );
      storage.failSave = false;
      await controller.select();
      expect(container.read(appearanceProvider).saveFailed, false);
      expect(storage.saved?.palette, AppPalette.graphite);
      final immediateStorage = _DelayedAppearance();
      final immediate = ProviderContainer(
        overrides: [
          appearanceRepositoryProvider.overrideWithValue(
            AppearanceRepository(immediateStorage),
          ),
        ],
      );
      addTearDown(immediate.dispose);
      immediate.read(appearanceProvider);
      await immediate
          .read(appearanceProvider.notifier)
          .select(palette: AppPalette.forest);
      immediateStorage.loaded.complete(const AppearanceSettings());
      await Future<void>.delayed(Duration.zero);
      expect(
        immediate.read(appearanceProvider).settings.palette,
        AppPalette.forest,
      );
    },
  );

  testWidgets(
    'Ajustes aplica paleta y modo, con texto ampliado y movimiento reducido',
    (tester) async {
      tester.view.physicalSize = const Size(360, 950);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final storage = MemoryAppearance();
      final container = ProviderContainer(
        overrides: [
          appearanceRepositoryProvider.overrideWithValue(
            AppearanceRepository(storage),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              final settings = ref.watch(appearanceProvider).settings;
              return MaterialApp(
                theme: AppTheme.forPalette(
                  settings.palette,
                  settings.mode == AppearanceMode.dark
                      ? Brightness.dark
                      : Brightness.light,
                ),
                themeAnimationDuration: Duration.zero,
                home: const AppearanceScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oscuro').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Cyberpunk'));
      await tester.tap(find.text('Cyberpunk'));
      await tester.pumpAndSettle();
      expect(storage.saved?.mode, AppearanceMode.dark);
      expect(storage.saved?.palette, AppPalette.iris);
      expect(
        AppColors.of(tester.element(find.text('Cyberpunk'))).primary,
        AppColors.forPalette(AppPalette.iris, Brightness.dark).primary,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
