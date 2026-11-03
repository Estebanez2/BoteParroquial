import 'dart:io';
import 'dart:ui' as ui;
import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:bote_parroquial/core/routing/app_route.dart';
import 'package:bote_parroquial/models/appearance_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final _boundary = GlobalKey();
Future<void> _fonts(WidgetTester tester) async => tester.runAsync(() async {
  for (final (family, asset) in [
    ('Manrope', 'assets/fonts/Manrope-Variable.ttf'),
    ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
  ]) {
    await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
  }
});
Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('EXPORT_COLOR_MOTION')) return;
  final boundary =
      _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final root = Directory('.dart_tool/color_motion_preview');
    await root.create(recursive: true);
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '${root.path}/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  testWidgets(
    'Cuadrado, arcoíris y hexadecimal se sincronizan; inválido no se confirma',
    (tester) async {
      tester.view.physicalSize = const Size(412, 1050);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _fonts(tester);
      Color? saved;
      await tester.pumpWidget(
        RepaintBoundary(
          key: _boundary,
          child: MaterialApp(
            theme: AppTheme.light,
            home: AppScaffold(
              child: AppColorField(
                label: 'Color principal',
                value: const Color(0xFFFF0000),
                onChanged: (v) => saved = v,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Color principal'));
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byType(AppColorPlane));
      await tester.tapAt(
        Offset(rect.left + rect.width * .75, rect.top + rect.height * .25),
      );
      await tester.pumpAndSettle();
      final color = tester
          .widget<AppColorPlane>(find.byType(AppColorPlane))
          .value;
      expect(color.saturation, closeTo(.75, .01));
      expect(color.value, closeTo(.75, .01));
      await _capture(tester, 'visual-picker');
      await tester.ensureVisible(find.byType(AppHueSlider));
      await tester.tapAt(tester.getCenter(find.byType(Slider)));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AppColorPlane>(find.byType(AppColorPlane)).value.hue,
        closeTo(180, 2),
      );
      await tester.ensureVisible(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), '#00FF80');
      await tester.pump();
      expect(
        tester
            .widget<AppColorPlane>(find.byType(AppColorPlane))
            .value
            .toColor()
            .toARGB32(),
        0xFF00FF80,
      );
      await tester.enterText(find.byType(TextFormField), 'ZZ');
      await tester.pump();
      expect(
        tester
            .widget<AppButton>(
              find.widgetWithText(AppButton, 'Usar este color'),
            )
            .onPressed,
        isNull,
      );
      expect(saved, isNull);
      await tester.enterText(find.byType(TextFormField), '00FF80');
      await tester.pump();
      await tester.ensureVisible(find.text('Usar este color'));
      await tester.tap(find.text('Usar este color'));
      await tester.pumpAndSettle();
      expect(saved!.toARGB32(), 0xFF00FF80);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Una pulsación completa su ciclo, evita dobles y cancela al deshabilitar',
    (tester) async {
      var calls = 0;
      final enabled = ValueNotifier(true);
      addTearDown(enabled.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: enabled,
              builder: (_, value, _) => AppButton(
                label: 'Acción',
                onPressed: value ? () => calls++ : null,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Acción'));
      expect(calls, 0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 70));
      expect(
        tester
            .widget<ScaleTransition>(
              find
                  .descendant(
                    of: find.byType(AppPressFeedback),
                    matching: find.byType(ScaleTransition),
                  )
                  .first,
            )
            .scale
            .value,
        lessThan(1),
      );
      await tester.tap(find.text('Acción'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      await tester.tap(find.text('Acción'));
      await tester.pump(const Duration(milliseconds: 40));
      enabled.value = false;
      await tester.pumpAndSettle();
      expect(calls, 1);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: AppButton(label: 'Directa', onPressed: () => calls++),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Directa'));
      expect(calls, 2);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Tarjeta espera el pulso y las rutas animan; atrás y movimiento reducido conservan navegación',
    (tester) async {
      tester.view.physicalSize = const Size(412, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final reduced = ValueNotifier(false);
      addTearDown(reduced.dispose);
      final router = GoRouter(
        routes: [
          appRoute(
            path: '/',
            builder: (context, _) => AppScaffold(
              child: AppCard(
                variant: AppCardVariant.interactive,
                onTap: () => context.push('/two'),
                child: const Text('Grupo'),
              ),
            ),
          ),
          appRoute(
            path: '/two',
            builder: (_, _) => const AppScaffold(child: Text('Destino')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        RepaintBoundary(
          key: _boundary,
          child: ValueListenableBuilder(
            valueListenable: reduced,
            builder: (_, value, _) => MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
              builder: (_, child) => MediaQuery(
                data: MediaQueryData(disableAnimations: value),
                child: child!,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grupo'));
      expect(router.routeInformationProvider.value.uri.path, '/');
      for (var i = 0; i < 12 && find.text('Destino').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      await tester.pump(const Duration(milliseconds: 32));
      expect(find.text('Destino'), findsOneWidget);
      expect(find.byType(SlideTransition), findsWidgets);
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();
      reduced.value = true;
      await tester.pumpAndSettle();
      expect(
        MediaQuery.disableAnimationsOf(tester.element(find.text('Grupo'))),
        isTrue,
      );
      await tester.tap(find.text('Grupo'));
      for (var i = 0; i < 3 && find.text('Destino').evaluate().isEmpty; i++) {
        await tester.pump();
      }
      expect(find.text('Destino'), findsOneWidget);
      expect(find.byType(SlideTransition), findsNothing);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Cuatro identidades nuevas, ambos modos y Atlántico conservado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(850, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _fonts(tester);
    expect(AppPaletteCatalog.label(AppPalette.atlantic), 'Atlántico');
    expect(
      AppColors.forPalette(
        AppPalette.atlantic,
        Brightness.light,
      ).primary.toARGB32(),
      0xFF2459C4,
    );
    expect(
      AppColors.forPalette(
        AppPalette.atlantic,
        Brightness.dark,
      ).primary.toARGB32(),
      0xFFAAC5FF,
    );
    expect(
      AppColors.forPalette(
        AppPalette.atlantic,
        Brightness.light,
      ).secondary.toARGB32(),
      0xFF98501C,
    );
    final stored = AppearanceSettings.fromJson({
      'version': 1,
      'palette': 'iris',
      'mode': 'dark',
    });
    expect(AppPaletteCatalog.label(stored.palette), 'Cyberpunk');
    final palettes = AppPalette.values.skip(1).toList();
    for (final brightness in Brightness.values) {
      expect(
        palettes
            .map(
              (p) => AppColors.forPalette(p, brightness).background.toARGB32(),
            )
            .toSet()
            .length,
        4,
      );
      await tester.pumpWidget(
        RepaintBoundary(
          key: _boundary,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (var row = 0; row < 2; row++)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var col = 0; col < 2; col++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    Text(
                                      AppPaletteCatalog.label(
                                        palettes[row * 2 + col],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    AppThemePreview(
                                      theme: AppTheme.forPalette(
                                        palettes[row * 2 + col],
                                        brightness,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, 'radical-palettes-${brightness.name}');
      expect(tester.takeException(), isNull);
    }
  });
}
