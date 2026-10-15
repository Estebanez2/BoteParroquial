import 'dart:async';
import 'package:bote_parroquial/app/app.dart';
import 'package:bote_parroquial/app/router.dart';
import 'package:bote_parroquial/core/firebase/firebase_bootstrap.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_sync_providers.dart';
import 'package:bote_parroquial/features/persons/providers/person_providers.dart';
import 'package:bote_parroquial/models/group_member.dart';
import 'package:bote_parroquial/models/person.dart';
import 'package:bote_parroquial/repositories/person_repository.dart';
import 'package:bote_parroquial/services/person_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'auth_flow_test.dart' as auth;
import 'groups_test.dart' as groups;

class MemoryPersons implements PersonService {
  final changes = StreamController<List<Person>>.broadcast();
  List<Person> current = [];
  final writtenGroups = <String>[];
  int revision = 0;
  @override
  Stream<List<Person>> watchPersons(String groupId) async* {
    yield current;
    yield* changes.stream;
  }

  void _store(
    String groupId,
    String uid,
    String name,
    String? notes,
    bool active,
  ) {
    writtenGroups.add(groupId);
    current = [
      Person(
        id: 'p1',
        groupId: groupId,
        displayName: name,
        notes: notes,
        isActive: active,
        createdBy: uid,
        updatedBy: uid,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026, 1, 1, 0, 0, ++revision),
      ),
    ];
    changes.add(current);
  }

  @override
  Future<void> create(
    String groupId,
    String uid,
    String name,
    String? notes,
  ) async => _store(groupId, uid, name, notes, true);
  @override
  Future<void> edit(
    String groupId,
    String uid,
    Person person,
    String name,
    String? notes,
  ) async => _store(groupId, uid, name, notes, person.isActive);
  @override
  Future<void> setActive(
    String groupId,
    String uid,
    Person person,
    bool active,
  ) async => _store(groupId, uid, person.displayName, person.notes, active);
}

void main() {
  testWidgets(
    'Personas: validar, crear, editar, inactivar/reactivar y limitar al miembro',
    (tester) async {
      tester.view.physicalSize = const Size(412, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = auth.FakeAuthRepository(auth.alice);
      final membership = groups.FakeGroups();
      final service = MemoryPersons();
      final container = ProviderContainer(
        overrides: [
          groupServerConfirmedProvider.overrideWith(
            (ref, groupId) => Stream.value(true),
          ),
          firebaseStartupProvider.overrideWithValue(
            FirebaseStartup.ready(auth.FakeApp()),
          ),
          authRepositoryProvider.overrideWithValue(session),
          userProfileRepositoryProvider.overrideWithValue(
            auth.FakeProfileRepository(),
          ),
          groupRepositoryProvider.overrideWithValue(membership),
          personRepositoryProvider.overrideWithValue(PersonRepository(service)),
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
      Future<void> tap(String label) async {
        if ((label == 'Activar' || label == 'Inactivar') &&
            find.text(label).evaluate().isEmpty) {
          await tester.ensureVisible(find.byTooltip('Más opciones').last);
          await tester.tap(find.byTooltip('Más opciones').last);
          await tester.pumpAndSettle();
        }
        final target = label == 'Editar'
            ? find.byTooltip('Editar').last
            : find.text(label).last;
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      await tap('Añadir persona');
      await tap('Guardar persona');
      expect(find.text('Escribe el nombre de la persona.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '  Ana  ');
      await tester.enterText(find.byType(TextFormField).last, '  Nota  ');
      await tap('Guardar persona');
      expect(find.text('Ana'), findsOneWidget);
      expect(service.current.single.notes, 'Nota');
      await tap('Editar');
      await tester.enterText(find.byType(TextFormField).first, 'Ana María');
      await tap('Guardar persona');
      expect(find.text('Ana María'), findsOneWidget);
      await tap('Inactivar');
      await tap('Inactivar persona');
      expect(service.current.single.isActive, isFalse);
      expect(find.text('Inactiva'), findsOneWidget);
      await tap('Activar');
      await tap('Activar persona');
      expect(service.current.single.isActive, isTrue);
      expect(service.current.single.id, 'p1');
      expect(service.writtenGroups, everyElement('a'));
      membership.current = [
        groups.member('a', 'alice', role: GroupRole.member),
      ];
      membership.changes.add(membership.current);
      await tester.pumpAndSettle();
      expect(find.text('Ana María'), findsOneWidget);
      expect(find.text('Añadir persona'), findsNothing);
      expect(find.byTooltip('Editar'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
