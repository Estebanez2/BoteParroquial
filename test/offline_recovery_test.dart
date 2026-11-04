import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/core/offline/offline_mode.dart';
import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:bote_parroquial/features/offline/presentation/daily_copies_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'support/idle_daily_copies.dart';

void main() {
  testWidgets(
    'Red y cuota ofrecen copias sin reemplazar reintento ni escapar del visor',
    (tester) async {
      var retries = 0;
      var failure = const AppFailure(FailureCode.network, 'Sin red');
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: DailyCopyRecovery(
                error: failure,
                child: AppButton(
                  label: 'Reintentar',
                  onPressed: () => retries++,
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/offline',
            builder: (_, _) => const Scaffold(body: Text('Catálogo local')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyCopyControllerProvider.overrideWith(IdleDailyCopies.new),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(retries, 1);
      await tester.tap(find.text('Copias para consultar sin conexión'));
      await tester.pumpAndSettle();
      expect(find.text('Catálogo local'), findsOneWidget);

      failure = firestoreQuotaFailure;
      router.go('/');
      await tester.pumpAndSettle();
      expect(find.text('Reintentar'), findsOneWidget);
      await tester.tap(find.text('Copias para consultar sin conexión'));
      await tester.pumpAndSettle();
      expect(find.text('Catálogo local'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      for (final readOnly in [false, true]) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [offlineReadOnlyProvider.overrideWithValue(readOnly)],
            child: MaterialApp(
              home: Scaffold(
                body: DailyCopyRecovery(
                  error: AppFailure(
                    readOnly
                        ? FailureCode.network
                        : FailureCode.permissionDenied,
                    'No disponible',
                  ),
                  child: const Text('Error original'),
                ),
              ),
            ),
          ),
        );
        expect(find.byType(DailyCopyEntryButton), findsNothing);
        expect(find.text('Error original'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
}
