import 'dart:async';
import 'package:bote_parroquial/app/app.dart';
import 'package:bote_parroquial/app/router.dart';
import 'package:bote_parroquial/core/firebase/firebase_bootstrap.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_sync_providers.dart';
import 'package:bote_parroquial/features/persons/providers/person_providers.dart';
import 'package:bote_parroquial/features/movements/providers/movement_providers.dart';
import 'package:bote_parroquial/models/movement.dart';
import 'package:bote_parroquial/models/person.dart';
import 'package:bote_parroquial/models/pending_movement.dart';
import 'package:bote_parroquial/repositories/movement_repository.dart';
import 'package:bote_parroquial/services/movement_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'auth_flow_test.dart' as auth;
import 'groups_test.dart' as groups;
import 'support/memory_pending_movements.dart';

class MemoryMovements implements MovementService {
  final changes = StreamController<List<Movement>>.broadcast();
  List<Movement> current = [];
  int counter = 0, revision = 0;
  @override
  String newId(String groupId) => 'm${++counter}';
  @override
  Future<List<Movement>> loadMovements(String groupId) async => current;
  @override
  Stream<List<Movement>> watchMovements(String groupId) async* {
    yield current;
    yield* changes.stream;
  }

  Movement transition(
    Movement m,
    MovementStatus status,
    String uid,
    String reason, {
    String? replacement,
  }) => Movement(
    id: m.id,
    groupId: m.groupId,
    input: m.input,
    status: status,
    createdBy: m.createdBy,
    createdAt: m.createdAt,
    updatedAt: DateTime.utc(2026, 1, 1, 0, 0, ++revision),
    cancelledBy: status == MovementStatus.cancelled ? uid : null,
    cancelledAt: status == MovementStatus.cancelled ? DateTime.utc(2026) : null,
    cancellationReason: status == MovementStatus.cancelled ? reason : null,
    correctedBy: status == MovementStatus.corrected ? uid : null,
    correctedAt: status == MovementStatus.corrected ? DateTime.utc(2026) : null,
    correctionReason: status == MovementStatus.corrected ? reason : null,
    correctedByMovementId: replacement,
    correctionOfMovementId: m.correctionOfMovementId,
  );
  @override
  Future<void> save(
    String groupId,
    String id,
    String uid,
    MovementInput input, {
    Movement? original,
    String? reason,
  }) async {
    if (original != null) {
      current = current
          .map(
            (m) => m.id == original.id
                ? transition(
                    m,
                    MovementStatus.corrected,
                    uid,
                    reason!,
                    replacement: id,
                  )
                : m,
          )
          .toList();
    }
    current = [
      ...current,
      Movement(
        id: id,
        groupId: groupId,
        input: input,
        status: MovementStatus.active,
        createdBy: uid,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026, 1, 1, 0, 0, ++revision),
        correctionOfMovementId: original?.id,
      ),
    ];
    changes.add(current);
  }

  @override
  Future<void> cancel(
    String groupId,
    Movement m,
    String uid,
    String reason,
  ) async {
    current = current
        .map(
          (row) => row.id == m.id
              ? transition(row, MovementStatus.cancelled, uid, reason)
              : row,
        )
        .toList();
    changes.add(current);
  }
}

void main() {
  testWidgets(
    'Flujo financiero: céntimos, advertencias, corrección y anulación sin doble saldo',
    (tester) async {
      tester.view.physicalSize = const Size(412, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = auth.FakeAuthRepository(auth.alice),
          membership = groups.FakeGroups(),
          service = MemoryMovements();
      final journal = MemoryPendingMovements();
      final person = Person(
        id: 'inactive',
        groupId: 'a',
        displayName: 'Marta',
        isActive: false,
        createdBy: 'alice',
        updatedBy: 'alice',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final container = ProviderContainer(
        overrides: [
          groupServerConfirmedProvider.overrideWith(
            (ref, groupId) => Stream.value(true),
          ),
          pendingMovementServiceProvider.overrideWithValue(journal),
          firebaseStartupProvider.overrideWithValue(
            FirebaseStartup.ready(auth.FakeApp()),
          ),
          authRepositoryProvider.overrideWithValue(session),
          userProfileRepositoryProvider.overrideWithValue(
            auth.FakeProfileRepository(),
          ),
          groupRepositoryProvider.overrideWithValue(membership),
          personsProvider.overrideWith(
            (ref, groupId) => Stream.value([person]),
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
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BoteParroquialApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);
      Future<void> tap(String text) async {
        await tester.ensureVisible(find.text(text).last);
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      }

      router.go('/groups/a/movements');
      await tester.pumpAndSettle();
      await tap('Registrar ingreso');
      await tester.enterText(find.byType(TextFormField).first, '20,50');
      await tap('Revisar y guardar');
      expect(find.text('Selecciona la persona del ingreso.'), findsOneWidget);
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tap('Marta · Inactiva');
      await tap('Revisar y guardar');
      expect(find.text('La persona está inactiva'), findsOneWidget);
      await tap('Continuar con persona inactiva');
      expect(service.current.single.input.amountCents, 2050);
      await tap('Registrar retirada');
      await tester.enterText(find.byType(TextFormField).first, '30');
      await tester.enterText(find.byType(TextFormField).last, 'Material');
      await tap('Revisar y guardar');
      expect(find.text('El bote quedará en negativo'), findsOneWidget);
      await tap('Cancelar');
      expect(service.current.length, 1);
      await tap('Revisar y guardar');
      await tap('Confirmar saldo negativo');
      expect(MovementRepository.balanceOf(service.current), -950);
      router.go('/groups/a/movements/m1/correct');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '10');
      await tester.enterText(
        find.byType(TextFormField).last,
        'Importe correcto',
      );
      await tap('Revisar y guardar');
      await tap('Continuar con persona inactiva');
      await tap('Confirmar saldo negativo');
      expect(service.current.first.input.amountCents, 2050);
      expect(service.current.first.status, MovementStatus.corrected);
      expect(MovementRepository.balanceOf(service.current), -2000);
      router.go('/groups/a/movements/m2/cancel');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).last,
        'Retirada duplicada',
      );
      await tap('Revisar anulación');
      await tap('Anular movimiento');
      expect(MovementRepository.balanceOf(service.current), 1000);
      expect(
        service.current
            .where((m) => m.status == MovementStatus.cancelled)
            .length,
        1,
      );
      await journal.write(
        PendingMovement(
          groupId: 'a',
          actorUid: 'alice',
          id: 'recovered',
          input: MovementInput(
            type: MovementType.income,
            amountCents: 250,
            occurredAt: DateTime.utc(2025),
            description: 'Recuperado',
            personId: 'inactive',
          ),
        ),
      );
      container.invalidate(pendingMovementProvider('a'));
      await tester.pumpAndSettle();
      expect(find.text('Envío pendiente de confirmar'), findsOneWidget);
      await tap('Comprobar y recuperar envío');
      await tap('Continuar con persona inactiva');
      await tap('Reintentar el mismo envío');
      expect(service.current.last.id, 'recovered');
      expect(MovementRepository.balanceOf(service.current), 1250);
      expect(await journal.read('alice', 'a'), isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
