import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Selectores y botones expandidos responden en todo el hueco, con foco y disabled conservados',
    (tester) async {
      for (final brightness in Brightness.values) {
        var selected = 0, presses = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: brightness == Brightness.dark
                ? AppTheme.dark
                : AppTheme.light,
            home: Scaffold(
              body: SizedBox(
                width: 400,
                child: StatefulBuilder(
                  builder: (context, setState) => Column(
                    children: [
                      AppChoiceBar<int>(
                        options: const {0: 'Ingreso', 1: 'Retirada'},
                        value: selected,
                        onChanged: (value) => setState(() => selected = value),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Ver',
                              onPressed: () => presses++,
                            ),
                          ),
                        ],
                      ),
                      AppChoiceBar<bool>(
                        options: const {true: 'Sí', false: 'No'},
                        value: true,
                        onChanged: (_) => presses++,
                        enabled: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final bar = tester.getRect(find.byType(AppChoiceBar<int>));
        // Inside the visible segment, well away from its short label.
        await tester.tapAt(Offset(bar.right - AppSpacing.md, bar.center.dy));
        await tester.pumpAndSettle();
        expect(selected, 1);
        await tester.tapAt(Offset(bar.left + AppSpacing.md, bar.center.dy));
        await tester.pumpAndSettle();
        expect(selected, 0);
        final button = tester.getRect(find.widgetWithText(TextButton, 'Ver'));
        expect(button.width, greaterThan(350));
        await tester.tapAt(
          Offset(button.right - AppSpacing.md, button.center.dy),
        );
        await tester.pumpAndSettle();
        expect(presses, 1);
        final disabled = tester.getRect(find.byType(AppChoiceBar<bool>));
        await tester.tapAt(
          Offset(disabled.right - AppSpacing.md, disabled.center.dy),
        );
        await tester.pumpAndSettle();
        expect(presses, 1);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Acciones separadas de texto y botones vecinos, y cabecera desplegable visible y pulsable',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Importes de esta persona'),
                    AppButton(label: 'Ver ficha', onPressed: () {}),
                    AppButton(label: 'Abrir papelera', onPressed: () {}),
                    Wrap(
                      children: [
                        AppButton(label: 'Corregir', onPressed: () {}),
                        AppButton(label: 'Anular', onPressed: () {}),
                      ],
                    ),
                    AppExpandableRow(
                      title: const Text('Gestionar este espacio'),
                      children: [
                        AppButton(label: 'Editar grupo', onPressed: () {}),
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
      Rect button(String label) =>
          tester.getRect(find.widgetWithText(TextButton, label));
      expect(
        button('Ver ficha').top -
            tester.getRect(find.text('Importes de esta persona')).bottom,
        greaterThanOrEqualTo(AppSpacing.sm),
      );
      expect(
        button('Abrir papelera').top - button('Ver ficha').bottom,
        greaterThanOrEqualTo(AppSpacing.sm),
      );
      expect(
        button('Anular').left - button('Corregir').right,
        greaterThanOrEqualTo(AppSpacing.sm),
      );
      final tile = tester.widget<ExpansionTile>(find.byType(ExpansionTile));
      expect(tile.collapsedShape, isA<RoundedRectangleBorder>());
      expect(
        (tile.collapsedShape! as RoundedRectangleBorder).side.width,
        greaterThan(1),
      );
      final header = tester.getRect(find.byType(ExpansionTile));
      await tester.tapAt(
        Offset(header.right - AppSpacing.xl, header.center.dy),
      );
      await tester.pumpAndSettle();
      expect(find.text('Editar grupo').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
