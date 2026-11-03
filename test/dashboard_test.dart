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
import 'package:bote_parroquial/features/movements/presentation/movements_screen.dart';
import 'package:bote_parroquial/design_system/platform/app_deferred_section.dart';
import 'package:bote_parroquial/repositories/dashboard_repository.dart';
import 'package:bote_parroquial/repositories/movement_repository.dart';
import 'package:bote_parroquial/repositories/movement_history_repository.dart';
import 'package:bote_parroquial/repositories/person_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/idle_daily_copies.dart';
import 'auth_flow_test.dart' as auth;
import 'groups_test.dart' as groups;
import 'movements_test.dart' as money;
import 'persons_test.dart' as people;

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
  cancellationReason: status == MovementStatus.cancelled ? 'Anulado' : null,
  correctedAt: status == MovementStatus.corrected
      ? DateTime.utc(2026, 10, day)
      : null,
  correctedBy: 'alice',
  correctionReason: status == MovementStatus.corrected ? 'Corregido' : null,
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
      final personService = people.MemoryPersons();
      service.current = [movement('income', 1000)];
      final confirmation = StreamController<bool>.broadcast();
      final container = ProviderContainer(
        overrides: [
          dailyCopyControllerProvider.overrideWith(IdleDailyCopies.new),
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
          personRepositoryProvider.overrideWithValue(
            PersonRepository(personService),
          ),
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
        await personService.changes.close();
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
      expect(find.text('Actualización pendiente'), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Actualización pendiente'), findsOneWidget);
      confirmation.add(true);
      await tester.pumpAndSettle();
      expect(find.text('Actualización pendiente'), findsNothing);
      expect(
        tester.widget<BalanceCard>(find.byType(BalanceCard)).balanceCents,
        1000,
      );
      Future<void> tap(String text) async {
        await tester.ensureVisible(find.text(text).last);
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      }

      expect(find.text('Ver movimientos'), findsNothing);
      expect(find.text('Ver personas'), findsNothing);
      expect(find.text('Ver miembros'), findsNothing);
      expect(find.text('Informes del grupo'), findsNothing);
      final cover = tester.widget<AppCover>(find.byType(AppCover));
      expect(cover.panoramic, true);
      expect(tester.getSize(find.byType(AppCover)).width, 360);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: false);
      await tester.pumpAndSettle();
      final indicator = find.byKey(const ValueKey('navigation-indicator'));
      final indicatorElement = tester.element(indicator);
      final initialIndicator = tester
          .widget<AnimatedAlign>(indicator)
          .alignment;
      for (final tab in ['Actividad', 'Informes', 'Participantes']) {
        final pill = find.descendant(
          of: indicator,
          matching: find.byType(DecoratedBox),
        );
        final previousX = tester.getCenter(pill).dx;
        await tester.tap(
          find.descendant(
            of: find.byType(AppBottomNavigation),
            matching: find.text(tab),
          ),
        );
        await tester.pump();
        expect(identical(tester.element(indicator), indicatorElement), true);
        expect(
          tester.widget<AnimatedAlign>(indicator).alignment,
          isNot(initialIndicator),
        );
        await tester.pump(const Duration(milliseconds: 40));
        final intermediateX = tester.getCenter(pill).dx;
        expect(intermediateX, greaterThan(previousX));
        await tester.pumpAndSettle();
        expect(tester.getCenter(pill).dx, greaterThan(intermediateX));
        expect(router.canPop(), true);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/groups/a');
      }
      Future<void> selectSection(String label) async {
        await tester.tap(
          find.descendant(
            of: find.byType(AppBottomNavigation),
            matching: find.text(label),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));
      }

      double incomingX(int index) => tester
          .widget<SlideTransition>(
            find
                .ancestor(
                  of: find.byWidgetPredicate(
                    (widget) =>
                        widget is AppDeferredSection &&
                        widget.sectionIndex == index,
                  ),
                  matching: find.byType(SlideTransition),
                )
                .first,
          )
          .position
          .value
          .dx;
      await selectSection('Informes');
      await tester.pumpAndSettle();
      await selectSection('Actividad');
      expect(incomingX(1), lessThan(0));
      expect(find.byType(MovementsScreen), findsNothing);
      expect(incomingX(1) + 1, closeTo(incomingX(3), .02));
      await tester.pumpAndSettle();
      expect(find.byType(MovementsScreen), findsOneWidget);
      await selectSection('Informes');
      expect(incomingX(3), greaterThan(0));
      await tester.pumpAndSettle();
      await selectSection('Inicio');
      expect(incomingX(0), lessThan(0));
      await tester.pumpAndSettle();
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomNavigation),
          matching: find.text('Participantes'),
        ),
      );
      await tester.pumpAndSettle();
      await tap('Ver personas');
      expect(find.text('Añadir persona'), findsOneWidget);
      await tap('Añadir persona');
      expect(find.byType(AppBottomNavigation), findsNothing);
      expect(find.text('Guardar persona'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNavigation), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap('Ver miembros');
      expect(find.text('Tú'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/groups/a/participants',
      );
      router.go('/groups/a');
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/');
      expect(find.text('CADA APORTE CUENTA'), findsNothing);
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
      expect(find.byType(AppBottomNavigation), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
