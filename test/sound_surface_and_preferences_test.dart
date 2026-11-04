import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:bote_parroquial/models/ui_sound_settings.dart';
import 'package:bote_parroquial/services/device_ui_sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Solo acciones: zonas libres y controles deshabilitados callan; volver es distinto',
    (tester) async {
      final heard = <UiSound>[];
      var actions = 0;
      await tester.pumpWidget(
        AppSoundSurface(
          onSound: heard.add,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Column(
                children: [
                  AppButton(label: 'Compartido', onPressed: () => actions++),
                  AppButton(label: 'Deshabilitado', onPressed: null),
                  AppIconButton(
                    icon: Icons.arrow_back_rounded,
                    label: 'Volver',
                    onPressed: () => actions++,
                  ),
                  const Text('Zona libre'),
                  AppDropdown<String>(
                    label: 'Opciones',
                    options: const {'a': 'Primero', 'b': 'Segundo'},
                    value: 'a',
                    onChanged: (_) => actions++,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Compartido'));
      await tester.pumpAndSettle();
      expect(heard, [UiSound.tap]);
      expect(actions, 1);
      await tester.tap(find.text('Zona libre'));
      await tester.pumpAndSettle();
      expect(heard.length, 1);
      await tester.tap(find.text('Deshabilitado'));
      await tester.pumpAndSettle();
      expect(heard.length, 1);
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(heard.last, UiSound.back);
      expect(actions, 2);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Segundo').last);
      await tester.pumpAndSettle();
      expect(heard.length, 4);
      expect(actions, 3);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Preferencias conservan apagado antiguo y restauran volumen sin audio nativo',
    () async {
      final root = await Directory.systemTemp.createTemp('bote-sounds-');
      addTearDown(() async {
        expect(root.parent.absolute.path, Directory.systemTemp.absolute.path);
        await root.delete(recursive: true);
      });
      await File('${root.path}/ui-sounds.txt').writeAsString('off');
      final service = DeviceUiSoundService(directory: () async => root);
      addTearDown(service.dispose);
      final legacy = await service.loadSettings();
      expect(legacy.enabled, isFalse);
      expect(legacy.volumePercent, 75);
      await service.saveSettings(const UiSoundSettings(volumePercent: 72));
      final restored = await DeviceUiSoundService(
        directory: () async => root,
      ).loadSettings();
      expect(restored.volumePercent, 72);
      expect(restored.enabled, isTrue);
      await service.saveSettings(restored.copyWith(enabled: false));
      expect((await service.loadSettings()).enabled, isFalse);
      expect(UiSoundSettings.fromJson(restored.toJson()).volumePercent, 72);
    },
  );

  test(
    'Clics variados sin repetición inmediata ni archivos inesperados',
    () async {
      final choices = UiClickVariants(random: Random(17));
      final assets = List.generate(100, (_) => choices.nextAsset());
      expect(assets.toSet(), {'press_1', 'press_2', 'press_3'});
      for (var i = 1; i < assets.length; i++) {
        expect(assets[i], isNot(assets[i - 1]));
      }
      final menu = UiClickVariants(
        random: Random(17),
        prefix: 'click',
        count: 4,
      );
      expect(List.generate(30, (_) => menu.nextAsset()).toSet(), {
        'click_1',
        'click_2',
        'click_3',
        'click_4',
      });
      final hashes = [
        '77bc83f7f647ddd18ca2e39484573f5489534db53c163593488155a270735857',
        '31d1c90833d85ec881e3fe498726bc713dab6e8759cb71138dca2bc656117ca2',
        'efcb0d6f5b22314e72a58f942da9764c35e18d108708caab396cb2b56c4ea98d',
      ];
      for (var i = 0; i < hashes.length; i++) {
        expect(
          sha256
              .convert(
                await File('assets/sounds/press_${i + 1}.wav').readAsBytes(),
              )
              .toString(),
          hashes[i],
        );
      }
    },
  );

  testWidgets('Identidad compacta adapta nombre largo y texto ampliado', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const Scaffold(
            appBar: AppTopBar(
              title: 'Participantes',
              actions: [
                AppCompactIdentity(name: 'Nombre de grupo de prueba muy largo'),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Nombre de grupo de prueba muy largo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
