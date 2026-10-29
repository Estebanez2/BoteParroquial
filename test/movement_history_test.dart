import 'package:bote_parroquial/app/app.dart';
import 'package:bote_parroquial/app/router.dart';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/core/firebase/firebase_bootstrap.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_sync_providers.dart';
import 'package:bote_parroquial/features/movements/providers/movement_providers.dart';
import 'package:bote_parroquial/features/persons/providers/person_providers.dart';
import 'package:bote_parroquial/features/photos/providers/photo_providers.dart';
import 'package:bote_parroquial/models/movement.dart';
import 'package:bote_parroquial/models/movement_history_filter.dart';
import 'package:bote_parroquial/repositories/movement_history_repository.dart';
import 'package:bote_parroquial/repositories/movement_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'auth_flow_test.dart' as auth;
import 'dashboard_test.dart' as dashboard;
import 'groups_test.dart' as groups;
import 'movements_test.dart' as money;

Movement row(
  String id, {
  String groupId = 'a',
  MovementType type = MovementType.income,
  MovementStatus status = MovementStatus.active,
  String? personId = 'p',
  String author = 'alice',
  int day = 15,
}) => Movement(
  id: id,
  groupId: groupId,
  input: MovementInput(
    type: type,
    amountCents: 2050,
    occurredAt: DateTime.utc(2026, 10, day),
    description: 'Colecta para música',
    personId: personId,
  ),
  status: status,
  createdBy: author,
  createdAt: DateTime.utc(2026, 11, 1),
  updatedAt: DateTime.utc(2026, 11, 1),
  cancellationReason: status == MovementStatus.cancelled
      ? 'Anotación duplicada'
      : null,
);

void main() {
  const repository = MovementHistoryRepository();
  final rows = [
    row('first', day: 14),
    row('last'),
    row('outside', day: 16),
    row('cancelled', status: MovementStatus.cancelled),
    row('corrected', status: MovementStatus.corrected),
    row('other', personId: 'q', author: 'bob'),
    row('group', type: MovementType.withdrawal, personId: null),
  ];
  const persons = {'p': 'María López', 'q': 'José Ruiz'};
  const authors = {'alice': 'Ana Pérez', 'bob': 'Luis'};

  test(
    'Historial combina criterios, límites inclusivos y búsqueda sin acentos',
    () {
      final filtered = repository.filter(
        'a',
        rows,
        MovementHistoryFilter(
          query: '  MARIA   musica PEREZ ',
          type: MovementType.income,
          status: MovementStatus.active,
          personId: 'p',
          authorUid: 'alice',
          fromDate: DateTime(2026, 10, 14, 23),
          toDate: DateTime(2026, 10, 15),
        ),
        persons: persons,
        authors: authors,
      );
      expect(filtered.map((m) => m.id), ['last', 'first']);
      expect(
        repository
            .filter('a', rows, const MovementHistoryFilter(groupOnly: true))
            .single
            .id,
        'group',
      );
      expect(
        repository
            .filter(
              'a',
              rows,
              const MovementHistoryFilter(
                status: MovementStatus.cancelled,
                query: 'duplicada',
              ),
            )
            .single
            .id,
        'cancelled',
      );
      expect(
        repository.filter(
          'a',
          rows,
          const MovementHistoryFilter(query: 'inexistente'),
        ),
        isEmpty,
      );
    },
  );

  test(
    'Historial preserva estados y saldo, rechaza otro grupo e intervalos inválidos',
    () {
      final balance = MovementRepository.balanceOf(rows);
      final all = repository.filter('a', rows, const MovementHistoryFilter());
      expect(all.length, rows.length);
      expect(all.first.id, 'outside');
      expect(all.map((m) => m.status), containsAll(MovementStatus.values));
      expect(MovementRepository.balanceOf(rows), balance);
      expect(() => all.clear(), throwsUnsupportedError);
      expect(
        () => repository.filter('a', [
          ...rows,
          row('foreign', groupId: 'b'),
        ], const MovementHistoryFilter(query: 'never matches')),
        throwsA(isA<AppFailure>()),
      );
      expect(
        () => repository.filter(
          'a',
          rows,
          MovementHistoryFilter(
            fromDate: DateTime.utc(2026, 10, 16),
            toDate: DateTime.utc(2026, 10, 15),
          ),
        ),
        throwsA(isA<AppFailure>()),
      );
      final options = repository.options(
        'a',
        [row('unknown', personId: 'missing', author: 'past')],
        persons: persons,
        authors: authors,
      );
      expect(options.persons.keys, containsAll(['p', 'q', 'missing']));
      expect(options.authors['past'], 'Usuario no disponible');
    },
  );

  testWidgets(
    'Historial: buscar, aplicar/cancelar, tiempo real, foco y reinicio por grupo',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
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
      final session = auth.FakeAuthRepository(auth.alice);
      final membership = groups.FakeGroups();
      final service = money.MemoryMovements()
        ..current = [
          row('income'),
          row('withdrawal', type: MovementType.withdrawal, personId: null),
        ];
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
            (ref, groupId) => Stream.value(true),
          ),
          pendingMovementProvider.overrideWith((ref, groupId) async => null),
          personsProvider.overrideWith(
            (ref, groupId) => Stream.value([dashboard.person('p', false)]),
          ),
          movementRepositoryProvider.overrideWithValue(
            MovementRepository(service),
          ),
          photoPresentationProvider.overrideWith(
            (ref, target) => (bytes: null, loading: false),
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
      final router = container.read(routerProvider);
      router.go('/groups/a/movements');
      await tester.pumpAndSettle();
      Future<void> tap(String text) async {
        await tester.ensureVisible(find.text(text).last);
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      }

      Future<void> choose(String label, String option) async {
        final dropdown = find.ancestor(
          of: find.text(label),
          matching: find.byType(DropdownButtonFormField<String>),
        );
        await tester.ensureVisible(dropdown);
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        await tap(option);
      }

      await tester.ensureVisible(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'nada');
      await tester.pumpAndSettle();
      expect(find.text('No hay coincidencias'), findsOneWidget);
      await tap('Mostrar todos los movimientos');
      expect(find.text('2 movimientos encontrados'), findsOneWidget);
      await tap('Filtros');
      await choose('Tipo', 'Retiradas');
      await tap('Cancelar');
      expect(find.text('2 movimientos encontrados'), findsOneWidget);
      await tap('Filtros');
      await choose('Tipo', 'Ingresos');
      await tap('Aplicar filtros');
      expect(find.text('1 movimiento encontrado'), findsOneWidget);
      service.current = [...service.current, row('new')];
      service.changes.add(service.current);
      await tester.pumpAndSettle();
      expect(find.text('2 movimientos encontrados'), findsOneWidget);
      expect(service.counter, 0);
      expect(
        container
            .read(movementHistoryProvider(('a', 'withdrawal')))
            .asData
            ?.value
            .single
            .id,
        'withdrawal',
      );
      expect(container.read(movementFilterProvider('b')).criteriaCount, 0);
      expect(MovementRepository.balanceOf(service.current), 2050);
      await tap('Limpiar filtros');
      expect(find.text('3 movimientos encontrados'), findsOneWidget);
      // Reuse this flow for the retained light theme without another test matrix.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BoteParroquialApp(themeMode: ThemeMode.light),
        ),
      );
      await tester.pumpAndSettle();
      await tap('Filtros');
      expect(tester.takeException(), isNull);
      await tap('Cancelar');
      expect(tester.takeException(), isNull);
    },
  );
}
