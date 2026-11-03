import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:bote_parroquial/design_system/lab/motion_lab_catalog.dart';
import 'package:bote_parroquial/design_system/lab/motion_lab_transitions.dart';
import 'package:bote_parroquial/design_system/lab/motion_lab_buttons.dart';
import 'package:bote_parroquial/design_system/lab/motion_lab_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Entrar con código tiene llave y conserva su acción', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          floatingActionButton: AppFloatingActions<String>(
            label: 'Añadir',
            items: const {
              'create': 'Crear un nuevo grupo',
              'join': 'Entrar con código',
            },
            icons: const {'join': Icons.key_rounded},
            onSelected: (value) => selected = value,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Añadir'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.key_rounded), findsOneWidget);
    await tester.tap(find.text('Entrar con código'));
    await tester.pumpAndSettle();
    expect(selected, 'join');
  });

  testWidgets(
    'El catálogo de rutas permite entrar y volver en todos los efectos',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      final selectedEffect = ValueNotifier(LabPageEffect.none);
      addTearDown(selectedEffect.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Navigator(
            key: navigator,
            onGenerateInitialRoutes: (_, _) => [
              MotionLabTransitions.route(
                effect: LabPageEffect.none,
                duration: const Duration(milliseconds: 80),
                outgoingEffect: selectedEffect,
                child: const Scaffold(body: Text('Origen')),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(LabPageEffect.values.map((e) => e.id).toSet().length, 24);
      for (final effect in LabPageEffect.values) {
        selectedEffect.value = effect;
        navigator.currentState!.push<void>(
          MotionLabTransitions.route(
            effect: effect,
            duration: const Duration(milliseconds: 80),
            child: Scaffold(body: Text('Destino ${effect.id}')),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Destino ${effect.id}'), findsOneWidget);
        navigator.currentState!.pop();
        await tester.pumpAndSettle();
        expect(find.text('Origen'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: effect.id);
      }
    },
  );

  testWidgets(
    'Los botones completan un efecto finito, evitan dobles y respetan reducción',
    (tester) async {
      var calls = 0;
      for (final effect in LabButtonEffect.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 260,
                  child: MotionLabButton(
                    key: ValueKey(effect),
                    effect: effect,
                    duration: const Duration(milliseconds: 80),
                    onTested: () => calls++,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final previous = calls;
        await tester.tap(find.text('Probar ${effect.id}'));
        await tester.tap(find.text('Probar ${effect.id}'));
        await tester.pumpAndSettle();
        expect(calls, previous + 1);
        expect(tester.hasRunningAnimations, false);
        expect(tester.takeException(), isNull, reason: effect.id);
      }
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MotionLabButton(
              effect: LabButtonEffect.press,
              duration: const Duration(seconds: 1),
              onTested: () => calls++,
            ),
          ),
        ),
      );
      final previous = calls;
      await tester.tap(find.text('Probar B01'));
      expect(calls, previous + 1);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Laboratorio: velocidad, secciones, apertura y Atrás sin salir del catálogo',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          navigatorKey: navigator,
          home: const Scaffold(body: Text('Inicio real')),
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: child!,
          ),
        ),
      );
      navigator.currentState!.push<void>(
        MaterialPageRoute(builder: (_) => const MotionLabScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Laboratorio de animaciones'), findsOneWidget);
      await tester.scrollUntilVisible(find.byType(Slider), 100);
      await tester.drag(find.byType(Slider), const Offset(45, 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('Duración: 400 ms'), findsNothing);
      await tester.scrollUntilVisible(find.text('Abrir P01'), 100);
      await tester.tap(find.text('Abrir P01'));
      await tester.pumpAndSettle();
      expect(find.text('Prueba P01'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Laboratorio de animaciones'), findsOneWidget);
      expect(find.text('Inicio real'), findsNothing);
      await tester.ensureVisible(find.text('Botones'));
      await tester.tap(find.text('Botones'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Probar B01'), 100);
      expect(find.text('Probar B01'), findsOneWidget);
      await tester.ensureVisible(find.text('Barra'));
      await tester.tap(find.text('Barra'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.bySemanticsLabel('N01 Actividad'),
        100,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('N01 Actividad'));
      await tester.pumpAndSettle();
      tester
          .state<ScrollableState>(find.byType(Scrollable).last)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.textContaining('probadas'), 100);
      await tester.pumpAndSettle();
      expect(find.textContaining('2 probadas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
