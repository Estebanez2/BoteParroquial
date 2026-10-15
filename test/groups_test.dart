import 'dart:async';
import 'package:bote_parroquial/app/app.dart';
import 'package:bote_parroquial/app/router.dart';
import 'package:bote_parroquial/core/firebase/firebase_bootstrap.dart';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/persons/providers/person_providers.dart';
import 'package:bote_parroquial/features/movements/providers/movement_providers.dart';
import 'package:bote_parroquial/models/group.dart';
import 'package:bote_parroquial/models/group_member.dart';
import 'package:bote_parroquial/repositories/group_repository.dart';
import 'package:bote_parroquial/services/group_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'auth_flow_test.dart' as fixtures;

GroupMember member(
  String groupId,
  String uid, {
  bool active = true,
  GroupRole role = GroupRole.member,
}) => GroupMember(
  groupId: groupId,
  uid: uid,
  displayName: uid,
  role: role,
  isActive: active,
  joinedAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

class FakeGroups implements GroupRepository, GroupService {
  bool failMemberships = false;
  final changes = StreamController<List<GroupMember>>.broadcast();
  List<GroupMember> current = [
    member('a', 'alice', role: GroupRole.owner),
    member('b', 'alice', role: GroupRole.admin),
  ];
  final groupRequests = <String>[];
  @override
  Stream<List<GroupMember>> watchMemberships(String uid) async* {
    if (failMemberships) {
      throw const AppFailure(
        FailureCode.network,
        'No hay conexión con tus grupos.',
      );
    }
    yield current.where((m) => m.uid == uid && m.isActive).toList();
    yield* changes.stream.map(
      (members) => members.where((m) => m.uid == uid && m.isActive).toList(),
    );
  }

  @override
  Stream<Group?> watchGroup(String groupId) {
    groupRequests.add(groupId);
    return Stream.value(
      Group(
        id: groupId,
        name: groupId == 'a' ? 'Encuentro' : 'Horizonte',
        currency: 'EUR',
        timeZone: 'Europe/Madrid',
        isActive: true,
        createdBy: 'alice',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
  }

  @override
  Stream<List<GroupMember>> watchMembers(String groupId) =>
      Stream.value(current.where((m) => m.groupId == groupId).toList());
}

class UnfilteredMemberships extends FakeGroups {
  @override
  Stream<List<GroupMember>> watchMemberships(String uid) =>
      Stream.value(current);
}

void main() {
  test(
    'Repository descarta membresías inactivas y pertenecientes a otra cuenta',
    () async {
      final service = UnfilteredMemberships()
        ..current = [
          member('a', 'alice'),
          member('b', 'bob'),
          member('c', 'alice', active: false),
        ];
      final result = await DefaultGroupRepository(
        service,
      ).watchMemberships('alice').first;
      expect(result.map((m) => m.groupId), ['a']);
      await service.changes.close();
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'Dos grupos, aislamiento de rutas, revocación y cambio de cuenta (${dark ? 'oscuro' : 'claro'})',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final auth = fixtures.FakeAuthRepository(fixtures.alice);
        final groups = FakeGroups();
        final container = ProviderContainer(
          overrides: [
            firebaseStartupProvider.overrideWithValue(
              FirebaseStartup.ready(fixtures.FakeApp()),
            ),
            authRepositoryProvider.overrideWithValue(auth),
            userProfileRepositoryProvider.overrideWithValue(
              fixtures.FakeProfileRepository(),
            ),
            groupRepositoryProvider.overrideWithValue(groups),
            movementsProvider.overrideWith(
              (ref, groupId) => Stream.value(const []),
            ),
            personsProvider.overrideWith(
              (ref, groupId) => Stream.value(const []),
            ),
          ],
        );
        addTearDown(() async {
          container.dispose();
          await auth.changes.close();
          await groups.changes.close();
        });
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(1.6),
                disableAnimations: true,
              ),
              child: const BoteParroquialApp(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Encuentro'), findsOneWidget);
        expect(find.text('Horizonte'), findsOneWidget);
        final router = container.read(routerProvider);
        router.go('/groups/a');
        await tester.pumpAndSettle();
        expect(find.text('Encuentro'), findsOneWidget);
        expect(find.text('Horizonte'), findsNothing);
        expect(find.text('Propietario'), findsWidgets);
        router.go('/groups/b');
        await tester.pumpAndSettle();
        expect(find.text('Horizonte'), findsOneWidget);
        expect(find.text('Encuentro'), findsNothing);
        router.go('/groups/foreign');
        await tester.pumpAndSettle();
        expect(find.text('Este espacio no está disponible'), findsOneWidget);
        expect(groups.groupRequests, isNot(contains('foreign')));
        router.go('/groups/a');
        await tester.pumpAndSettle();
        auth.emit(fixtures.bob);
        await tester.pumpAndSettle();
        expect(find.text('Encuentro'), findsNothing);
        expect(find.text('Este espacio no está disponible'), findsOneWidget);
        auth.emit(fixtures.alice);
        await tester.pumpAndSettle();
        expect(find.text('Encuentro'), findsOneWidget);
        groups.current = [];
        groups.changes.add([]);
        await tester.pumpAndSettle();
        expect(find.text('Encuentro'), findsNothing);
        expect(find.text('Este espacio no está disponible'), findsOneWidget);
        auth.emit(fixtures.bob);
        await tester.pumpAndSettle();
        expect(find.text('Encuentro'), findsNothing);
        router.go('/');
        await tester.pumpAndSettle();
        expect(find.text('Hola, Roberto'), findsOneWidget);
        expect(find.text('Tu próximo espacio empieza aquí'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Un fallo de membresías permite reintento explícito', (
    tester,
  ) async {
    final auth = fixtures.FakeAuthRepository(fixtures.alice);
    final groups = FakeGroups()..failMemberships = true;
    final container = ProviderContainer(
      overrides: [
        firebaseStartupProvider.overrideWithValue(
          FirebaseStartup.ready(fixtures.FakeApp()),
        ),
        authRepositoryProvider.overrideWithValue(auth),
        userProfileRepositoryProvider.overrideWithValue(
          fixtures.FakeProfileRepository(),
        ),
        groupRepositoryProvider.overrideWithValue(groups),
        movementsProvider.overrideWith(
          (ref, groupId) => Stream.value(const []),
        ),
        personsProvider.overrideWith((ref, groupId) => Stream.value(const [])),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await auth.changes.close();
      await groups.changes.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BoteParroquialApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No hay conexión con tus grupos.'), findsOneWidget);
    groups.failMemberships = false;
    await tester.ensureVisible(find.text('Reintentar grupos'));
    await tester.tap(find.text('Reintentar grupos'));
    await tester.pumpAndSettle();
    expect(find.text('Encuentro'), findsOneWidget);
    expect(find.text('No hay conexión con tus grupos.'), findsNothing);
  });
}
