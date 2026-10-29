import 'dart:async';
import 'package:bote_parroquial/app/app.dart';
import 'package:bote_parroquial/app/router.dart';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/core/firebase/firebase_bootstrap.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_sync_providers.dart';
import 'package:bote_parroquial/features/groups/providers/member_role_providers.dart';
import 'package:bote_parroquial/features/movements/providers/movement_providers.dart';
import 'package:bote_parroquial/features/persons/providers/person_providers.dart';
import 'package:bote_parroquial/features/photos/providers/photo_providers.dart';
import 'package:bote_parroquial/models/group.dart';
import 'package:bote_parroquial/models/group_member.dart';
import 'package:bote_parroquial/repositories/member_role_repository.dart';
import 'package:bote_parroquial/services/member_role_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'auth_flow_test.dart' as auth;
import 'group_invitations_test.dart' as invitation;
import 'member_links_test.dart' as links;

class Roles implements MemberRoleService {
  Roles(this.groups);
  final invitation.LiveGroups groups;
  int roles = 0, transfers = 0;
  @override
  Future<void> changeRole(
    String id,
    String actor,
    GroupMember target,
    GroupRole role,
  ) async {
    roles++;
    groups.current = [
      for (final m in groups.current)
        if (m.uid == target.uid)
          links.member(m.uid, role: role, personId: m.personId)
        else
          m,
    ];
    groups.changes.add(groups.current);
  }

  @override
  Future<void> transfer(
    Group group,
    GroupMember owner,
    GroupMember recipient,
  ) async {
    transfers++;
    groups.current = [
      for (final m in groups.current)
        if (m.uid == owner.uid || m.uid == recipient.uid)
          links.member(
            m.uid,
            role: m.uid == owner.uid ? GroupRole.member : GroupRole.owner,
            personId: m.personId,
          )
        else
          m,
    ];
    groups.changes.add(groups.current);
  }
}

void main() {
  test(
    'Roles y propiedad validan grupo, actividad, vínculo y confirmación antes de escribir',
    () async {
      final groups = invitation.LiveGroups(),
          service = Roles(groups),
          repo = MemberRoleRepository(service);
      addTearDown(groups.changes.close);
      final owner = links.member('alice', role: GroupRole.owner),
          bob = links.member('bob', personId: 'p'),
          person = links.person('p', uid: 'bob');
      final group = await groups.watchGroup('a').first;
      expect(
        MemberRoleRepository.nextRole(bob, links.person('p', active: false)),
        isNull,
      );
      expect(
        MemberRoleRepository.nextRole(bob, links.person('p', uid: 'other')),
        isNull,
      );
      expect(
        MemberRoleRepository.canReceiveOwnership(owner, bob, person),
        true,
      );
      expect(
        () => repo.changeRole('b', 'alice', bob, person, GroupRole.admin),
        throwsA(isA<AppFailure>()),
      );
      expect(
        () => repo.changeRole('a', 'bob', bob, person, GroupRole.admin),
        throwsA(isA<AppFailure>()),
      );
      expect(
        () => repo.changeRole('a', 'alice', owner, null, GroupRole.member),
        throwsA(isA<AppFailure>()),
      );
      expect(
        () => repo.transfer(group!, owner, bob, person, 'incorrecto'),
        throwsA(isA<AppFailure>()),
      );
      expect(service.roles, 0);
      expect(service.transfers, 0);
      await repo.changeRole('a', 'alice', bob, person, GroupRole.admin);
      await repo.transfer(group!, owner, bob, person, group.name);
      expect(service.roles, 1);
      expect(service.transfers, 1);
    },
  );
  testWidgets(
    'Transferencia pide nombre y Google; cancelar o cambiar sesión no escribe; éxito conserva antiguo owner como miembro',
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
      final session = auth.FakeAuthRepository(auth.alice);
      final groups = invitation.LiveGroups()
        ..current = [
          links.member('alice', role: GroupRole.owner),
          links.member('bob', personId: 'Bob'),
          links.member('inactive', personId: 'Inactiva'),
        ];
      final service = Roles(groups);
      final container = ProviderContainer(
        overrides: [
          firebaseStartupProvider.overrideWithValue(
            FirebaseStartup.ready(auth.FakeApp()),
          ),
          authRepositoryProvider.overrideWithValue(session),
          userProfileRepositoryProvider.overrideWithValue(
            auth.FakeProfileRepository(),
          ),
          groupRepositoryProvider.overrideWithValue(groups),
          memberRoleRepositoryProvider.overrideWithValue(
            MemberRoleRepository(service),
          ),
          personsProvider.overrideWith(
            (ref, id) => Stream.value([
              links.person('Bob', uid: 'bob'),
              links.person('Inactiva', uid: 'inactive', active: false),
            ]),
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
        await groups.changes.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BoteParroquialApp(),
        ),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/groups/a/transfer');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(find.text('inactive'), findsNothing);
      await tester.tap(find.text('bob').last);
      await tester.pumpAndSettle();
      Future<void> submit() async {
        await tester.ensureVisible(find.text('Verificar Google y transferir'));
        await tester.tap(find.text('Verificar Google y transferir'));
        await tester.pumpAndSettle();
      }

      await submit();
      expect(session.reauthenticateCalls, 0);
      expect(service.transfers, 0);
      await tester.enterText(find.byType(TextFormField).last, 'Encuentro');
      session.reauthenticateAction = (_) async => throw const AppFailure(
        FailureCode.cancelled,
        'Verificación cancelada.',
      );
      await submit();
      expect(find.text('Verificación cancelada.'), findsOneWidget);
      expect(service.transfers, 0);
      final reauth = Completer<void>();
      session.reauthenticateAction = (_) => reauth.future;
      final group = container.read(groupProvider('a')).requireValue!;
      final target = groups.current.singleWhere((m) => m.uid == 'bob');
      final pending = container
          .read(memberRoleControllerProvider('a').notifier)
          .transfer(group, target, group.name);
      await tester.pump();
      session.emit(auth.bob);
      await tester.pumpAndSettle();
      reauth.complete();
      expect(await pending, false);
      expect(service.transfers, 0);
      session.emit(auth.alice);
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/groups/a/transfer');
      await tester.pumpAndSettle();
      session.reauthenticateAction = null;
      final saved = await container
          .read(memberRoleControllerProvider('a').notifier)
          .transfer(group, target, group.name);
      await tester.pumpAndSettle();
      expect(saved, true);
      expect(service.transfers, 1);
      expect(
        groups.current.singleWhere((m) => m.uid == 'alice').role,
        GroupRole.member,
      );
      expect(
        groups.current.singleWhere((m) => m.uid == 'bob').role,
        GroupRole.owner,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
