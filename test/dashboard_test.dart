import 'dart:async';
import 'package:bote_parroquial/app/app.dart';
import 'package:bote_parroquial/app/router.dart';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/core/firebase/firebase_bootstrap.dart';
import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_sync_providers.dart';
import 'package:bote_parroquial/features/movements/providers/movement_providers.dart';
import 'package:bote_parroquial/features/persons/providers/person_providers.dart';
import 'package:bote_parroquial/models/dashboard_summary.dart';
import 'package:bote_parroquial/models/movement.dart';
import 'package:bote_parroquial/models/person.dart';
import 'package:bote_parroquial/repositories/dashboard_repository.dart';
import 'package:bote_parroquial/repositories/movement_repository.dart';
import 'package:bote_parroquial/repositories/movement_history_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'auth_flow_test.dart' as auth;
import 'groups_test.dart' as groups;
import 'movements_test.dart' as money;

Movement movement(
  String id,
  int cents, {
  MovementType type = MovementType.income,
  MovementStatus status = MovementStatus.active,
  int day = 1,
  String? replacement,
  String? original,
}) => Movement(
  id: id,
  groupId: 'a',
  input: MovementInput(
    type: type,
    amountCents: cents,
    occurredAt: DateTime.utc(2026, 1, 1),
    description: 'Prueba',
    personId: 'p',
  ),
  status: status,
  createdBy: 'alice',
  createdAt: DateTime.utc(2026, 10, day),
  updatedAt: DateTime.utc(2026, 10, day),
  cancelledAt: status == MovementStatus.cancelled
      ? DateTime.utc(2026, 10, day)
      : null,
  cancelledBy: 'alice',
  cancellationReason: 'Anulado',
  correctedAt: status == MovementStatus.corrected
      ? DateTime.utc(2026, 10, day)
      : null,
  correctedBy: 'alice',
  correctionReason: 'Corregido',
  correctedByMovementId: replacement,
  correctionOfMovementId: original,
);
Person person(String id, bool active) => Person(
  id: id,
  groupId: 'a',
  displayName: 'Ana',
  isActive: active,
  createdBy: 'alice',
  updatedBy: 'alice',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  test(
    'Resumen independiente: estados financieros, personas, actividad, vacío y aislamiento',
    () {
      const repo = DashboardRepository();
      final rows = [
        movement('income', 2050),
        movement('withdrawal', 1500, type: MovementType.withdrawal),
        movement(
          'original',
          5000,
          status: MovementStatus.corrected,
          day: 14,
          replacement: 'replacement',
        ),
        movement('replacement', 2500, day: 14, original: 'original'),
        movement(
          'cancelled',
          999999,
          status: MovementStatus.cancelled,
          day: 15,
        ),
      ];
      final result = repo.summarize('a', rows, [
        person('p', true),
        person('q', false),
      ]);
      expect(result.incomeCents, 4550);
      expect(result.withdrawalCents, 1500);
      expect(result.balanceCents, 3050);
      expect(result.activePersonsCount, 1);
      expect(result.inactivePersonsCount, 1);
      expect(result.totalPersonsCount, 2);
      final days = const MovementHistoryRepository().groupByDay('a', rows);
      expect(days.single.movements.length, rows.length);
      expect(
        () => const MovementHistoryRepository().groupByDay('foreign', rows),
        throwsA(isA<AppFailure>()),
      );
      expect(result.recentActivity.first.kind, DashboardActivityKind.cancelled);
      expect(result.recentActivity.length, 4);
      expect(
        result.recentActivity
            .where((event) => event.kind == DashboardActivityKind.corrected)
            .single
            .input
            .amountCents,
        2500,
      );
      final empty = repo.summarize('a', [], []);
      expect(empty.balanceCents, 0);
      expect(empty.recentActivity, isEmpty);
      expect(repo.summarize('a', [rows[1]], []).isNegative, isTrue);
      expect(
        () => repo.summarize('foreign', rows, []),
        throwsA(isA<AppFailure>()),
      );
      expect(
        repo
            .summarize('a', [
              for (var i = 1; i <= 7; i++) movement('$i', 100, day: i),
            ], [])
            .recentActivity
            .length,
        5,
      );
    },
  );
  testWidgets(
    'Dashboard: actualiza, navega, oculta cifras en error y al revocar acceso',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final session = auth.FakeAuthRepository(auth.alice),
          membership = groups.FakeGroups(),
          service = money.MemoryMovements();
      service.current = [movement('income', 1000)];
      final confirmation = StreamController<bool>.broadcast();
      final container = ProviderContainer(
        overrides: [
          groupServerConfirmedProvider.overrideWith((ref, groupId) async* {
            yield false;
            yield* confirmation.stream;
          }),
          pendingMovementProvider.overrideWith((ref, groupId) async => null),
          firebaseStartupProvider.overrideWithValue(
            FirebaseStartup.ready(auth.FakeApp()),
          ),
          authRepositoryProvider.overrideWithValue(session),
          userProfileRepositoryProvider.overrideWithValue(
            auth.FakeProfileRepository(),
          ),
          groupRepositoryProvider.overrideWithValue(membership),
          personsProvider.overrideWith(
            (ref, groupId) => Stream.value([person('p', true)]),
          ),
          movementRepositoryProvider.overrideWithValue(
            MovementRepository(service),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await session.changes.close();
        await membership.changes.close();
        await service.changes.close();
        await confirmation.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BoteParroquialApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);
      router.go('/groups/a');
      await tester.pumpAndSettle();
      expect(find.text('Actualización sin confirmar'), findsOneWidget);
      confirmation.add(true);
      await tester.pumpAndSettle();
      expect(find.text('Actualización sin confirmar'), findsNothing);
      expect(
        tester.widget<BalanceCard>(find.byType(BalanceCard)).balanceCents,
        1000,
      );
      Future<void> tap(String text) async {
        await tester.ensureVisible(find.text(text).last);
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      }

      await tap('Ver personas');
      expect(find.text('Añadir persona'), findsOneWidget);
      router.go('/groups/a');
      await tester.pumpAndSettle();
      await tap('Ver miembros');
      expect(find.text('Tú'), findsOneWidget);
      router.go('/groups/a');
      await tester.pumpAndSettle();
      service.current = [
        movement('withdrawal', 1500, type: MovementType.withdrawal),
      ];
      service.changes.add(service.current);
      await tester.pumpAndSettle();
      expect(
        tester.widget<BalanceCard>(find.byType(BalanceCard)).balanceCents,
        -1500,
      );
      expect(find.text('Saldo negativo'), findsOneWidget);
      service.changes.addError(
        const AppFailure(FailureCode.network, 'Sin conexión al resumen.'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BalanceCard), findsNothing);
      expect(find.text('Sin conexión al resumen.'), findsOneWidget);
      await tap('Reintentar resumen');
      expect(find.byType(BalanceCard), findsOneWidget);
      membership.current = [];
      membership.changes.add([]);
      await tester.pumpAndSettle();
      expect(find.byType(BalanceCard), findsNothing);
      expect(find.text('Este espacio no está disponible'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
