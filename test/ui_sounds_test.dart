import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:bote_parroquial/repositories/ui_sound_repository.dart';
import 'package:bote_parroquial/services/ui_sound_service.dart';
import 'package:bote_parroquial/models/ui_sound_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _SoundService implements UiSoundService {
  bool fail = false;
  UiSoundSettings settings = const UiSoundSettings();
  final heard = <UiSound>[];
  final volumes = <double>[];
  int stops = 0;
  @override
  Future<UiSoundSettings> loadSettings() async => settings;
  @override
  Future<void> saveSettings(UiSoundSettings value) async => settings = value;
  @override
  Future<void> play(UiSound sound, {required double volume}) async {
    if (fail) throw StateError('audio unavailable');
    heard.add(sound);
    volumes.add(volume);
  }

  @override
  Future<void> stop() async => stops++;
  @override
  Future<void> dispose() async {}
}

void main() {
  test(
    'Cada edición suena sin filtros y conserva volumen, silencio y segundo plano',
    () async {
      final service = _SoundService();
      final repository = UiSoundRepository(service);
      await repository.restore();
      await repository.play(UiSound.typing);
      for (var i = 0; i < 10; i++) {
        await repository.play(UiSound.typing);
      }
      expect(service.heard.length, 11);
      await repository.play(UiSound.typing);
      expect(service.heard.length, 12);
      await repository.saveVolume(80);
      await repository.play(UiSound.tap);
      expect(service.volumes.last, .8);
      await repository.play(UiSound.success);
      expect(service.heard.last, UiSound.success);
      await repository.select(false);
      expect(service.settings.enabled, false);
      expect(service.stops, 1);
      await repository.play(UiSound.success);
      expect(service.heard.length, 14);
      await repository.select(true);
      repository.active = false;
      await repository.play(UiSound.photo);
      expect(service.heard.length, 14);
      repository.active = true;
      service.fail = true;
      await expectLater(repository.play(UiSound.tap), completes);
      final restored = await UiSoundRepository(service).restore();
      expect(restored.volumePercent, 80);
      expect(restored.enabled, isTrue);
      await repository.saveVolume(0);
      service.fail = false;
      await repository.play(UiSound.tap);
      expect(service.heard.length, 14);
    },
  );

  testWidgets(
    'Componentes emiten sonido por texto escrito y acciones sin enviar contenido',
    (tester) async {
      final sounds = <UiSound>[];
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        AppSoundScope(
          onSound: sounds.add,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    AppTextField(label: 'Nombre', controller: controller),
                    const AppTextField(label: 'Clave', password: true),
                    AppTextField(
                      label: 'Selector',
                      readOnly: true,
                      onTap: () {},
                    ),
                    AppToggleTile(
                      title: const Text('Casilla'),
                      checkbox: true,
                      value: false,
                      onChanged: (_) {},
                    ),
                    AppToggleTile(
                      title: const Text('Interruptor'),
                      value: false,
                      onChanged: (_) {},
                    ),
                    AppButton(
                      label: 'Guardar',
                      onPressed: () => AppSnackbar.show(
                        context,
                        'Guardado',
                        variant: AppSnackbarVariant.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      controller.text = 'Restaurado';
      await tester.pump();
      expect(sounds, isEmpty);
      await tester.enterText(find.byType(TextFormField).first, 'Nuevo');
      expect(sounds, [UiSound.typing]);
      await tester.enterText(find.byType(TextFormField).at(1), 'secreto');
      expect(sounds, [UiSound.typing, UiSound.typing]);
      await tester.tap(find.byType(TextFormField).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Casilla'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Interruptor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(sounds, [
        UiSound.typing,
        UiSound.typing,
        UiSound.tap,
        UiSound.tap,
        UiSound.tap,
        UiSound.tap,
        UiSound.success,
      ]);
    },
  );
}
