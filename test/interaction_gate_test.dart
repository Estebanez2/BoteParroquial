import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:bote_parroquial/design_system/platform/app_interaction_gate.dart';

void main() {
  testWidgets(
    'Onda de grupo y entrada bloquean Apariencia hasta completar la transición',
    (tester) async {
      var appearance = 0, opened = 0;
      AppInteractionGate? gate;
      await tester.pumpWidget(
        AppInteractionHost(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) {
                gate = AppInteractionScope.maybeOf(context);
                return AppScaffold(
                  child: Column(
                    children: [
                      AppGroupEntry(
                        onOpen: (_) {
                          opened++;
                          Navigator.of(context).push(
                            AppPageTransitions.formRoute(
                              context,
                              const AppScaffold(
                                child: Text('Dentro del grupo'),
                              ),
                            ),
                          );
                        },
                        builder: (_, activate) => AppButton(
                          label: 'Grupo',
                          tapEffect: AppTapEffect.none,
                          onPressed: activate,
                        ),
                      ),
                      TextButton(
                        onPressed: () => appearance++,
                        child: const Text('Apariencia'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Grupo'));
      await tester.pump();
      expect(gate!.busy, isTrue);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Apariencia'), warnIfMissed: false);
      expect(appearance, 0);
      expect(opened, 0);
      await tester.pump(const Duration(milliseconds: 850));
      await tester.pump();
      expect(opened, 1);
      expect(gate!.busy, isTrue);
      await tester.pumpAndSettle();
      expect(gate!.busy, isFalse);
      expect(find.text('Dentro del grupo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Pulsaciones simultáneas no compiten; desmontar cancela y libera el bloqueo',
    (tester) async {
      var first = 0, second = 0;
      final visible = ValueNotifier(true);
      addTearDown(visible.dispose);
      AppInteractionGate? gate;
      await tester.pumpWidget(
        AppInteractionHost(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) {
                gate = AppInteractionScope.maybeOf(context);
                return AppScaffold(
                  child: Column(
                    children: [
                      AppButton(label: 'Primero', onPressed: () => first++),
                      AppButton(label: 'Segundo', onPressed: () => second++),
                      ValueListenableBuilder<bool>(
                        valueListenable: visible,
                        builder: (_, show, _) => show
                            ? AppGroupEntry(
                                onOpen: (_) => first++,
                                builder: (_, activate) => AppButton(
                                  label: 'Grupo',
                                  tapEffect: AppTapEffect.none,
                                  onPressed: activate,
                                ),
                              )
                            : const Text('Sin grupo'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Primero'));
      await tester.tap(find.text('Segundo'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(first, 1);
      expect(second, 0);
      expect(gate!.busy, isFalse);
      await tester.tap(find.text('Grupo'));
      await tester.pump(const Duration(milliseconds: 100));
      visible.value = false;
      await tester.pumpAndSettle();
      expect(first, 1);
      expect(gate!.busy, isFalse);
      await tester.tap(find.text('Segundo'));
      await tester.pumpAndSettle();
      expect(second, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
