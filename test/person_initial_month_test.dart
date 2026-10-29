import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bote_parroquial/app/app.dart';
import 'package:bote_parroquial/app/router.dart';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/core/firebase/firebase_bootstrap.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_sync_providers.dart';
import 'package:bote_parroquial/features/movements/providers/movement_providers.dart';
import 'package:bote_parroquial/features/persons/providers/person_providers.dart';
import 'package:bote_parroquial/models/year_month.dart';
import 'package:bote_parroquial/repositories/group_calendar_repository.dart';
import 'package:bote_parroquial/repositories/person_repository.dart';
import 'package:bote_parroquial/services/group_clock_service.dart';
import 'auth_flow_test.dart' as auth;
import 'groups_test.dart' as groups;
import 'persons_test.dart' as people;

void main() {
  test(
    'Primer mes opcional no inventa participación y rechaza meses futuros',
    () async {
      final service = people.MemoryPersons(),
          repo = PersonRepository(service),
          june = YearMonth(2026, 6);
      addTearDown(service.changes.close);
      await repo.create('a', 'alice', 'Sin periodo', null);
      expect(service.periods, isEmpty);
      expect(
        () => repo.create(
          'a',
          'alice',
          'Futura',
          null,
          id: 'p1',
          firstMonth: YearMonth(2026, 7),
          currentMonth: june,
        ),
        throwsA(isA<AppFailure>()),
      );
    },
  );
  testWidgets(
    'Alta permite elegir el primer mes y confirmar antes de escribir',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1100);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final session = auth.FakeAuthRepository(auth.alice),
          membership = groups.FakeGroups(),
          service = people.MemoryPersons();
      final container = ProviderContainer(
        overrides: [
          firebaseStartupProvider.overrideWithValue(
            FirebaseStartup.ready(auth.FakeApp()),
          ),
          authRepositoryProvider.overrideWithValue(session),
          userProfileRepositoryProvider.overrideWithValue(
            auth.FakeProfileRepository(),
          ),
          groupRepositoryProvider.overrideWithValue(membership),
          groupServerConfirmedProvider.overrideWith(
            (ref, id) => Stream.value(true),
          ),
          personRepositoryProvider.overrideWithValue(PersonRepository(service)),
          groupCalendarRepositoryProvider.overrideWithValue(
            GroupCalendarRepository(
              TimeZoneGroupClockService(now: () => DateTime.utc(2026, 6, 15)),
            ),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await session.changes.close();
        await membership.changes.close();
        await service.changes.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BoteParroquialApp(),
        ),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/groups/a/persons');
      await tester.pumpAndSettle();
      Future<void> tap(String text) async {
        await tester.ensureVisible(find.text(text).last);
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      }

      await tap('Añadir persona');
      expect(find.text('Más adelante'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'DEMO mes explícito',
      );
      await tap('Elegir ahora');
      expect(find.text('Primer mes incluido'), findsOneWidget);
      await tap('Guardar persona');
      expect(service.current, isEmpty);
      await tap('Crear persona y periodo');
      expect(service.periods.single.firstMonth, YearMonth(2026, 6));
      expect(service.current.single.lastParticipationPeriodId, 'initial-p1');
      expect(tester.takeException(), isNull);
    },
  );
}
