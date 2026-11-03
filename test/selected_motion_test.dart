import 'package:bote_parroquial/core/routing/app_route.dart';
import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    'B07 B08 validan, B04 rechaza y B05 mantiene deshabilitado sin actuar',
    (tester) async {
      final form = GlobalKey<FormState>();
      final name = TextEditingController();
      addTearDown(name.dispose);
      var saves = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Form(
              key: form,
              child: Column(
                children: [
                  AppTextField(
                    label: 'Nombre',
                    controller: name,
                    validator: (value) => value?.trim().isNotEmpty == true
                        ? null
                        : 'Falta el nombre',
                  ),
                  AppButton(
                    key: const ValueKey('save'),
                    label: 'Guardar',
                    validate: () => form.currentState!.validate(),
                    onPressed: () => saves++,
                  ),
                  const AppButton(
                    key: ValueKey('blocked'),
                    label: 'Bloqueado',
                    onPressed: null,
                  ),
                  AppButton(
                    label: 'Secundario',
                    variant: AppButtonVariant.secondary,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('save'));
      final blocked = find.byKey(const ValueKey('blocked'));
      final saveControl = find.descendant(
        of: save,
        matching: find.byType(TextButton),
      );
      final before = tester.getCenter(saveControl);
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 25));
      expect(find.text('Falta el nombre'), findsOneWidget);
      expect(tester.getCenter(saveControl).dx, isNot(before.dx));
      expect(saves, 0);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bloqueado'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 25));
      expect(
        tester
            .widget<TextButton>(
              find.descendant(of: blocked, matching: find.byType(TextButton)),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.descendant(of: blocked, matching: find.byType(Transform)),
        findsWidgets,
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Ana');
      await tester.tap(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(saves, 0);
      await tester.pumpAndSettle();
      expect(saves, 1);
      expect(
        tester
            .widget<AppControlFeedback>(
              find.descendant(
                of: save,
                matching: find.byType(AppControlFeedback),
              ),
            )
            .effect,
        AppTapEffect.shine,
      );
      final secondary = find.widgetWithText(AppButton, 'Secundario');
      expect(
        tester
            .widget<AppControlFeedback>(
              find.descendant(
                of: secondary,
                matching: find.byType(AppControlFeedback),
              ),
            )
            .effect,
        AppTapEffect.wave,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: AppButton(
              label: 'Procesando',
              loading: true,
              onPressed: () => saves++,
            ),
          ),
        ),
      );
      expect(
        tester.widget<TextButton>(find.byType(TextButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('Procesando'));
      await tester.pumpAndSettle();
      expect(saves, 1);
    },
  );

  testWidgets(
    'Se cancela el envío visual al perder acceso, cambiar validación o desmontar',
    (tester) async {
      final enabled = ValueNotifier(true);
      addTearDown(enabled.dispose);
      var valid = true, calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: enabled,
              builder: (_, value, _) => AppButton(
                label: 'Acción',
                validate: () => valid,
                onPressed: value ? () => calls++ : null,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Acción'));
      await tester.pump();
      enabled.value = false;
      await tester.pumpAndSettle();
      expect(calls, 0);
      enabled.value = true;
      await tester.pumpAndSettle();
      await tester.tap(find.text('Acción'));
      await tester.pump();
      valid = false;
      await tester.pumpAndSettle();
      expect(calls, 0);
      valid = true;
      await tester.tap(find.text('Acción'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Grupo espera un segundo y expande desde su rectángulo; no secuestra otra ruta',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var entries = 0;
      final router = GoRouter(
        routes: [
          appRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: Center(
                child: SizedBox(
                  width: 260,
                  height: 180,
                  child: AppGroupEntry(
                    onOpen: (origin) {
                      entries++;
                      context.go('/group', extra: origin);
                    },
                    builder: (_, activate) => AppCard(
                      variant: AppCardVariant.interactive,
                      tapEffect: AppTapEffect.none,
                      onTap: activate,
                      child: const Text('Grupo'),
                    ),
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/group',
            pageBuilder: (_, state) => AppMotionPage<void>(
              key: state.pageKey,
              motion: AppPageMotion.group,
              origin: state.extra is AppGroupOrigin
                  ? (state.extra as AppGroupOrigin).rect
                  : null,
              child: const Scaffold(
                key: ValueKey('destination'),
                body: Text('Destino'),
              ),
            ),
          ),
          appRoute(
            path: '/other',
            builder: (_, _) => const Scaffold(body: Text('Otra pantalla')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
      await tester.pumpAndSettle();
      final origin = tester.getRect(find.byType(AppGroupEntry));
      await tester.tap(find.text('Grupo'));
      await tester.tap(find.text('Grupo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 999));
      expect(entries, 0);
      await tester.pump(const Duration(milliseconds: 2));
      await tester.pump();
      expect(entries, 1);
      final destination = find.byKey(const ValueKey('destination'));
      expect(tester.getRect(destination), origin);
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.getRect(destination).width, greaterThan(origin.width));
      await tester.pumpAndSettle();
      expect(tester.getRect(destination).width, 400);
      router.go('/');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grupo'));
      await tester.pump();
      router.push('/other');
      await tester.pumpAndSettle();
      expect(entries, 1);
      expect(find.text('Otra pantalla'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
