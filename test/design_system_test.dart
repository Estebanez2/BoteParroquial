import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:bote_parroquial/design_system/showcase/design_system_showcase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {bool dark = false, bool reduceMotion = true}) =>
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  test('Dinero se interpreta exactamente en céntimos sin coma flotante', () {
    expect(parseMoneyCents('20,50'), 2050);
    expect(parseMoneyCents('20.50'), 2050);
    expect(parseMoneyCents('0,01'), 1);
    expect(parseMoneyCents('0'), 0);
    expect(parseMoneyCents('999999999999,99'), 99999999999999);
    for (final invalid in [
      '',
      '-20',
      '1,001',
      '2.430,50',
      'texto',
      'NaN',
      '1e3',
    ]) {
      expect(parseMoneyCents(invalid), isNull, reason: invalid);
    }
    expect(formatMoneyCents(243050), '2.430,50 €');
    expect(formatMoneyCents(-1), '-0,01 €');
    expect(formatMoneyCents(2000, showPositiveSign: true), '+20,00 €');
    expect(formatMoneyCents(2050, currency: 'USD'), r'20,50 $');
  });

  test(
    'Texto y acciones principales tienen contraste legible en ambos modos',
    () {
      double contrast(Color a, Color b) {
        final x = a.computeLuminance();
        final y = b.computeLuminance();
        return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
      }

      for (final c in [AppColors.light, AppColors.dark]) {
        for (final foreground in [
          c.textPrimary,
          c.textSecondary,
          c.textMuted,
        ]) {
          expect(contrast(foreground, c.background), greaterThanOrEqualTo(4.5));
        }
        expect(contrast(c.primary, c.onPrimary), greaterThanOrEqualTo(4.5));
        expect(contrast(c.hero, c.onHero), greaterThanOrEqualTo(4.5));
      }
    },
  );

  testWidgets('Botón en carga o deshabilitado no dispara acciones', (
    tester,
  ) async {
    var actions = 0;
    await tester.pumpWidget(
      host(
        AppButton(label: 'Guardar', loading: true, onPressed: () => actions++),
      ),
    );
    final button = tester.widget<TextButton>(find.byType(TextButton));
    expect(button.onPressed, isNull);
    expect(find.byType(LoadingIndicator), findsOneWidget);
    await tester.pumpWidget(
      host(const AppButton(label: 'Guardar', onPressed: null)),
    );
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
    expect(actions, 0);
    await tester.pumpWidget(
      host(AppButton(label: 'Guardar', onPressed: () => actions++)),
    );
    await tester.tap(find.text('Guardar'));
    expect(actions, 1);
  });

  testWidgets('Campo monetario comunica int y bloquea decimales inválidos', (
    tester,
  ) async {
    int? cents;
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 320,
          child: AppMoneyField(
            currency: 'EUR',
            onChangedCents: (value) => cents = value,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), '20,50');
    expect(cents, 2050);
    await tester.enterText(find.byType(TextFormField), '20,501');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      '20,50',
    );
    expect(cents, 2050);
    await tester.enterText(find.byType(TextFormField), '');
    expect(cents, isNull);
  });

  testWidgets('Cancelar diálogo devuelve false sin confirmar la acción', (
    tester,
  ) async {
    bool? confirmed;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => AppButton(
            label: 'Abrir',
            onPressed: () async {
              confirmed = await AppDialog.show(
                context,
                title: 'Revisar',
                description: 'Una decisión de ejemplo.',
                variant: AppDialogVariant.danger,
                confirmLabel: 'Confirmar',
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(confirmed, isFalse);
    expect(find.text('Revisar'), findsNothing);
  });

  testWidgets('Selector de fecha funciona con calendario en español', (
    tester,
  ) async {
    DateTime? selected;
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 320,
          child: AppDateField(
            label: 'Fecha de prueba',
            value: DateTime(2026, 10, 15),
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();
    expect(find.text('Seleccionar'), findsOneWidget);
    await tester.tap(find.text('Seleccionar'));
    await tester.pumpAndSettle();
    expect(selected, DateTime(2026, 10, 15));
  });

  for (final dark in [false, true]) {
    for (var section = 0; section < 4; section++) {
      testWidgets(
        'Galería sección $section, modo ${dark ? 'oscuro' : 'claro'}, móvil estrecho y texto grande',
        (tester) async {
          tester.view.physicalSize = const Size(360, 800);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 1.6;
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          await tester.pumpWidget(
            DesignSystemShowcase(initialSection: section, initialDark: dark),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
