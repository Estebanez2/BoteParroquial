import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Salir advierte, permite seguir, revierte cambios y descarta sin escribir',
    (tester) async {
      final name = TextEditingController(text: 'Ana');
      final navigator = GlobalKey<NavigatorState>();
      final guard = GlobalKey<AppFormGuardState>();
      addTearDown(name.dispose);
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          theme: AppTheme.light,
          home: const Scaffold(body: Text('Listado')),
        ),
      );
      void open() {
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => AppFormGuard(
              key: guard,
              changes: name,
              isDirty: () => name.text != 'Ana',
              child: Scaffold(
                body: Column(
                  children: [
                    TextField(controller: name),
                    TextButton(
                      onPressed: () => guard.currentState!.requestExit(),
                      child: const Text('Atrás'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      open();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Ana María');
      await tester.tap(find.text('Atrás'));
      await tester.pumpAndSettle();
      expect(find.text('¿Salir sin guardar?'), findsOneWidget);
      await tester.tap(find.text('Seguir editando'));
      await tester.pumpAndSettle();
      expect(name.text, 'Ana María');
      await tester.enterText(find.byType(TextField), 'Ana');
      await tester.pump();
      await navigator.currentState!.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('Listado'), findsOneWidget);
      expect(find.text('¿Salir sin guardar?'), findsNothing);
      open();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Otro nombre');
      await tester.pump();
      await navigator.currentState!.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('¿Salir sin guardar?'), findsOneWidget);
      await tester.tap(find.text('Descartar cambios'));
      await tester.pumpAndSettle();
      expect(find.text('Listado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Un envío bloquea salir y un guardado confirmado no pregunta', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    final guard = GlobalKey<AppFormGuardState>();
    final busy = ValueNotifier(true);
    addTearDown(busy.dispose);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: Text('Listado')),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => ValueListenableBuilder<bool>(
          valueListenable: busy,
          builder: (_, value, _) => AppFormGuard(
            key: guard,
            busy: value,
            isDirty: () => true,
            child: const Scaffold(body: Text('Formulario')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await navigator.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Formulario'), findsOneWidget);
    expect(find.text('¿Salir sin guardar?'), findsNothing);
    busy.value = false;
    await tester.pumpAndSettle();
    guard.currentState!.saved();
    await tester.pump();
    await navigator.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Listado'), findsOneWidget);
  });
}
