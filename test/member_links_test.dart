import 'dart:async';
import 'package:bote_parroquial/app/app.dart';
import 'package:bote_parroquial/app/router.dart';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/core/firebase/firebase_bootstrap.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_sync_providers.dart';
import 'package:bote_parroquial/features/groups/providers/member_link_providers.dart';
import 'package:bote_parroquial/features/movements/providers/movement_providers.dart';
import 'package:bote_parroquial/features/persons/providers/person_providers.dart';
import 'package:bote_parroquial/features/photos/providers/photo_providers.dart';
import 'package:bote_parroquial/models/group_member.dart';
import 'package:bote_parroquial/models/person.dart';
import 'package:bote_parroquial/repositories/member_link_repository.dart';
import 'package:bote_parroquial/services/member_link_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'auth_flow_test.dart' as auth;
import 'group_invitations_test.dart' as invitation;

Person person(
  String id, {
  String groupId = 'a',
  String? uid,
  bool active = true,
}) => Person(
  id: id,
  groupId: groupId,
  displayName: id,
  isActive: active,
  linkedUid: uid,
  createdBy: 'alice',
  updatedBy: 'alice',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
GroupMember member(
  String uid, {
  String? personId,
  GroupRole role = GroupRole.member,
  bool active = true,
}) => GroupMember(
  groupId: 'a',
  uid: uid,
  displayName: uid,
  role: role,
  personId: personId,
  isActive: active,
  joinedAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

class Links implements MemberLinkService {
  Links(this.members);
  final invitation.LiveGroups members;
  final changes = StreamController<List<Person>>.broadcast();
  List<Person> persons = [
    person('Propietario', uid: 'alice'),
    person('Activa'),
    person('Inactiva', active: false),
    person('Reservada', uid: 'former'),
  ];
  int writes = 0;
  Stream<List<Person>> watch() async* {
    yield persons;
    yield* changes.stream;
  }

  @override
  Future<void> change(
    String groupId,
    String actorUid,
    GroupMember target,
    Person? previous,
    Person? next,
  ) async {
    writes++;
    members.current = [
      for (final row in members.current)
        if (row.groupId == groupId && row.uid == target.uid)
          member(
            row.uid,
            personId: next?.id,
            role: MemberLinkRepository.losesAdmin(row, next)
                ? GroupRole.member
                : row.role,
            active: row.isActive,
          )
        else
          row,
    ];
    persons = [
      for (final row in persons)
        if (row.id == previous?.id || row.id == next?.id)
          person(
            row.id,
            uid: row.id == next?.id ? target.uid : null,
            active: row.isActive,
          )
        else
          row,
    ];
    changes.add(persons);
    members.changes.add(members.current);
  }
}

void main() {
  test(
    'Vinculación valida grupo, reserva, propietario, baja e inactividad antes de escribir',
    () async {
      final members = invitation.LiveGroups(),
          service = Links(members),
          repo = MemberLinkRepository(service);
      addTearDown(() async {
        await service.changes.close();
        await members.changes.close();
      });
      final admin = member(
            'admin',
            role: GroupRole.admin,
            personId: 'admin-person',
          ),
          previous = person('admin-person', uid: 'admin');
      expect(
        MemberLinkRepository.losesAdmin(
          admin,
          person('inactive', active: false),
        ),
        true,
      );
      expect(MemberLinkRepository.losesAdmin(admin, null), true);
      expect(MemberLinkRepository.losesAdmin(admin, person('active')), false);
      expect(
        () => repo.change('b', 'alice', member('bob'), null, person('p')),
        throwsA(isA<AppFailure>()),
      );
      expect(
        () => repo.change(
          'a',
          'alice',
          member('bob'),
          null,
          person('p', uid: 'former'),
        ),
        throwsA(isA<AppFailure>()),
      );
      expect(
        () => repo.change(
          'a',
          'other',
          member('alice', role: GroupRole.owner, personId: 'owner'),
          person('owner', uid: 'alice'),
          null,
        ),
        throwsA(isA<AppFailure>()),
      );
      expect(
        () => repo.change(
          'a',
          'alice',
          member('former', active: false),
          null,
          person('p'),
        ),
        throwsA(isA<AppFailure>()),
      );
      await repo.change(
        'a',
        'alice',
        admin,
        previous,
        person('inactive', active: false),
      );
      expect(service.writes, 1);
    },
  );
  testWidgets(
    'Miembros sin vínculo, selector con reserva, advertencia de inactiva y guardado explícito',
    (tester) async {
      tester.view.physicalSize = const Size(360, 950);
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
          members = invitation.LiveGroups()
            ..current = [
              member('alice', role: GroupRole.owner, personId: 'Propietario'),
              member('bob'),
              member('former', personId: 'Reservada', active: false),
            ];
      final links = Links(members);
      final container = ProviderContainer(
        overrides: [
          firebaseStartupProvider.overrideWithValue(
            FirebaseStartup.ready(auth.FakeApp()),
          ),
          authRepositoryProvider.overrideWithValue(session),
          userProfileRepositoryProvider.overrideWithValue(
            auth.FakeProfileRepository(),
          ),
          groupRepositoryProvider.overrideWithValue(members),
          memberLinkRepositoryProvider.overrideWithValue(
            MemberLinkRepository(links),
          ),
          personsProvider.overrideWith(
            (ref, id) => id == 'a' ? links.watch() : Stream.value([]),
          ),
          movementsProvider.overrideWith((ref, id) => Stream.value([])),
          groupServerConfirmedProvider.overrideWith(
            (ref, id) => Stream.value(true),
          ),
          pendingMovementProvider.overrideWith((ref, id) async => null),
          photoPresentationProvider.overrideWith(
            (ref, target) => (bytes: null, loading: false),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await session.changes.close();
        await members.changes.close();
        await links.changes.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BoteParroquialApp(),
        ),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/groups/a/members');
      await tester.pumpAndSettle();
      Future<void> tap(String text) async {
        await tester.ensureVisible(find.text(text).last);
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      }

      await tap('Sin vínculo');
      expect(find.text('bob'), findsOneWidget);
      expect(find.text('former'), findsNothing);
      await tap('Vincular persona');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(find.text('Reservada'), findsNothing);
      await tap('Inactiva (inactiva)');
      expect(
        find.textContaining('Persona inactiva: conserva el historial'),
        findsOneWidget,
      );
      await tap('Guardar vinculación');
      expect(links.writes, 0);
      await tap('Confirmar vinculación');
      expect(links.writes, 1);
      expect(find.text('Todos tienen su vínculo'), findsOneWidget);
      await tap('Todos');
      expect(find.text('Persona: Inactiva'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
