import 'package:bote_parroquial/core/routing/app_route.dart';
import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:bote_parroquial/design_system/platform/app_deferred_section.dart';
import 'package:bote_parroquial/design_system/platform/app_section_render_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('No construye ni consulta el destino durante el deslizamiento', (
    tester,
  ) async {
    var constructions = 0;
    final router = GoRouter(
      routes: [
        appRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Origen')),
        ),
        appRoute(
          path: '/section',
          motion: AppPageMotion.section,
          sectionIndex: 1,
          builder: (_, _) {
            constructions++;
            return const Scaffold(body: Text('Datos del destino'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    router.push('/section');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(constructions, 0);
    expect(find.byType(AppSkeleton), findsOneWidget);
    expect(find.text('Datos del destino'), findsNothing);
    await tester.pumpAndSettle();
    expect(constructions, 1);
    expect(find.text('Datos del destino'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Espera también a la entrada exterior del grupo y pausa sus tickers',
    (tester) async {
      final entrance = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 300),
      );
      addTearDown(entrance.dispose);
      var constructions = 0;
      entrance.forward();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AppSectionRenderScope(
            accessKey: 'account-a',
            canFreeze: true,
            outerAnimations: [entrance],
            child: AppDeferredSection(
              identity: 'group',
              sectionIndex: 0,
              builder: (_) {
                constructions++;
                return const Text('Grupo preparado');
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(constructions, 0);
      await tester.pumpAndSettle();
      expect(constructions, 1);
      entrance.forward(from: 0);
      await tester.pump();
      final surface = tester.widget<SnapshotWidget>(
        find.byType(SnapshotWidget),
      );
      expect(surface.controller.allowSnapshotting, true);
      expect(
        TickerMode.valuesOf(
          tester.element(find.text('Grupo preparado')),
        ).enabled,
        false,
      );
      await tester.pumpAndSettle();
      expect(surface.controller.allowSnapshotting, false);
      expect(
        TickerMode.valuesOf(
          tester.element(find.text('Grupo preparado')),
        ).enabled,
        true,
      );
    },
  );

  testWidgets(
    'Invalidar acceso o cambiar cuenta descarta el cuadro congelado inmediatamente',
    (tester) async {
      final access = ValueNotifier('a');
      final motion = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 300),
      );
      addTearDown(access.dispose);
      addTearDown(motion.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ValueListenableBuilder(
            valueListenable: access,
            builder: (_, account, _) => AppSectionRenderScope(
              accessKey: account,
              canFreeze: account != 'denied',
              outerAnimations: [motion],
              child: AppDeferredSection(
                identity: 'same-route',
                sectionIndex: 1,
                builder: (_) => Text(
                  account == 'denied' ? 'Acceso retirado' : 'Datos $account',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Datos a'), findsOneWidget);
      motion.forward();
      await tester.pump();
      expect(
        tester
            .widget<SnapshotWidget>(find.byType(SnapshotWidget))
            .controller
            .allowSnapshotting,
        true,
      );
      access.value = 'denied';
      await tester.pump();
      expect(find.text('Datos a'), findsNothing);
      expect(find.text('Acceso retirado'), findsOneWidget);
      expect(
        tester
            .widget<SnapshotWidget>(find.byType(SnapshotWidget))
            .controller
            .allowSnapshotting,
        false,
      );
      access.value = 'b';
      await tester.pump();
      expect(find.text('Datos a'), findsNothing);
      expect(find.text('Acceso retirado'), findsNothing);
      expect(find.text('Datos b'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Datos b'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
