import 'package:bote_parroquial/app/app.dart';
import 'package:bote_parroquial/core/firebase/firebase_bootstrap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('La pantalla inicial abre sin configurar Firebase', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: BoteParroquialApp()));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido a BoteParroquial'), findsOneWidget);
    expect(find.text('Configuración de Firebase pendiente.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Un fallo de Firebase no bloquea la pantalla', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseStartupProvider.overrideWithValue(
            FirebaseStartup.failed(StateError('Missing native configuration')),
          ),
        ],
        child: const BoteParroquialApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Firebase no disponible'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
