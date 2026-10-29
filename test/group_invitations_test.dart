import 'dart:async';
import 'package:bote_parroquial/app/app.dart';
import 'package:bote_parroquial/app/router.dart';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/core/firebase/firebase_bootstrap.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_invitation_providers.dart';
import 'package:bote_parroquial/features/groups/presentation/join_group_screen.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_sync_providers.dart';
import 'package:bote_parroquial/features/movements/providers/movement_providers.dart';
import 'package:bote_parroquial/features/persons/providers/person_providers.dart';
import 'package:bote_parroquial/features/photos/providers/photo_providers.dart';
import 'package:bote_parroquial/models/group_invitation.dart';
import 'package:bote_parroquial/models/group_member.dart';
import 'package:bote_parroquial/repositories/group_invitation_repository.dart';
import 'package:bote_parroquial/services/file_sharing_service.dart';
import 'package:bote_parroquial/services/group_invitation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'auth_flow_test.dart' as auth;
import 'groups_test.dart' as groups;

class Sharing extends Fake implements FileSharingService {
  String? copied, shared;
  @override
  Future<void> copyText(String text) async {
    copied = text;
  }

  @override
  Future<void> shareText(String text) async {
    shared = text;
  }
}

class LiveGroups extends groups.FakeGroups {
  @override
  Stream<List<GroupMember>> watchMembers(String id) async* {
    yield current.where((m) => m.groupId == id).toList();
    yield* changes.stream.map(
      (rows) => rows.where((m) => m.groupId == id).toList(),
    );
  }
}

class Invitations implements GroupInvitationService {
  Invitations(this.groups);
  final LiveGroups groups;
  final changes = StreamController<void>.broadcast();
  final code = InvitationCode(groupId: 'a', secret: 'a' * 32);
  InvitationSettings? settings;
  final requests = <GroupJoinRequest>[
    GroupJoinRequest(
      uid: 'bob',
      displayName: 'Roberto',
      status: JoinRequestStatus.pending,
      updatedAt: DateTime.utc(2026),
    ),
  ];
  Future<InvitationPreview>? delayedPreview;
  Completer<JoinRequestStatus>? delayedSubmit;
  int submits = 0, removals = 0, decisions = 0;
  bool readmission = false;
  @override
  Stream<InvitationSettings?> watchSettings(String groupId) async* {
    yield settings;
    yield* changes.stream.map((_) => settings);
  }

  @override
  Stream<List<GroupJoinRequest>> watchRequests(String groupId) async* {
    yield List.of(requests);
    yield* changes.stream.map((_) => List.of(requests));
  }

  @override
  Future<InvitationPreview> preview(InvitationCode code, String uid) async =>
      delayedPreview ??
      InvitationPreview(
        code: code,
        groupName: 'Encuentro',
        currency: 'EUR',
        requiresApproval: true,
        isReadmission: readmission,
      );
  @override
  Future<void> configure(
    String groupId,
    String uid, {
    required String newCode,
    required bool enabled,
    required bool requiresApproval,
    InvitationSettings? original,
  }) async {
    settings = InvitationSettings(
      code: InvitationCode(groupId: groupId, secret: newCode),
      enabled: enabled,
      requiresApproval: requiresApproval,
      updatedAt: DateTime.utc(2026),
    );
    changes.add(null);
  }

  @override
  Future<JoinRequestStatus> submit(
    InvitationPreview preview,
    String uid,
    String displayName,
  ) async {
    submits++;
    return delayedSubmit?.future ?? JoinRequestStatus.pending;
  }

  @override
  Future<void> decide(
    String groupId,
    String uid,
    GroupJoinRequest request,
    bool approve,
  ) async {
    decisions++;
    requests.removeWhere((row) => row.uid == request.uid);
    if (approve) {
      groups.current = [
        ...groups.current,
        groupsMember(groupId, request.uid, request.displayName),
      ];
      groups.changes.add(groups.current);
    }
    changes.add(null);
  }

  GroupMember groupsMember(
    String id,
    String uid,
    String name, {
    bool active = true,
  }) => GroupMember(
    groupId: id,
    uid: uid,
    displayName: name,
    role: GroupRole.member,
    isActive: active,
    joinedAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  @override
  Future<void> remove(String groupId, String uid, GroupMember target) async {
    removals++;
    groups.current = [
      for (final m in groups.current)
        if (m.groupId == groupId && m.uid == target.uid)
          groupsMember(groupId, m.uid, m.displayName, active: false)
        else
          m,
    ];
    groups.changes.add(groups.current);
  }
}

void main() {
  testWidgets(
    'Invitación conserva el código al iniciar sesión y abre su vista previa',
    (tester) async {
      final session = auth.FakeAuthRepository();
      final members = LiveGroups();
      final service = Invitations(members);
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
          groupInvitationRepositoryProvider.overrideWithValue(
            GroupInvitationRepository(service, Sharing()),
          ),
          photoPresentationProvider.overrideWith(
            (ref, target) => (bytes: null, loading: false),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await session.changes.close();
        await members.changes.close();
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
      router.go('/join/${service.code.value}');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/login');
      expect(
        router.routeInformationProvider.value.uri.queryParameters['invitation'],
        service.code.value,
      );
      session.emit(auth.alice);
      await tester.pumpAndSettle();
      expect(find.text('Ver invitación'), findsOneWidget);
      expect(find.byType(JoinGroupScreen), findsOneWidget);
      expect(
        container.read(joinGroupProvider).preview?.code.value,
        service.code.value,
      );
    },
  );
  test(
    'Contrato de códigos, aislamiento, propietario protegido y compartición explícita',
    () async {
      final members = LiveGroups(),
          service = Invitations(members),
          sharing = Sharing();
      addTearDown(() async {
        await service.changes.close();
        await members.changes.close();
      });
      final repo = GroupInvitationRepository(service, sharing);
      final secret = repo.newSecret();
      expect(secret, matches(r'^[A-Za-z0-9_-]{32}$'));
      expect(repo.parse(' a.$secret ').groupId, 'a');
      for (final value in ['', 'a.abc', '../a.$secret', 'a.$secret.extra']) {
        expect(() => repo.parse(value), throwsA(isA<AppFailure>()));
      }
      final settings = InvitationSettings(
        code: service.code,
        enabled: true,
        requiresApproval: true,
        updatedAt: DateTime.utc(2026),
      );
      expect(
        () => repo.configure(
          'b',
          'alice',
          enabled: true,
          requiresApproval: true,
          original: settings,
        ),
        throwsA(isA<AppFailure>()),
      );
      expect(
        () => repo.remove(
          'a',
          'alice',
          groups.member('a', 'alice', role: GroupRole.owner),
        ),
        throwsA(isA<AppFailure>()),
      );
      expect(
        () => repo.remove('b', 'alice', groups.member('a', 'bob')),
        throwsA(isA<AppFailure>()),
      );
      await repo.copy(settings);
      await repo.share(settings);
      expect(sharing.copied, settings.code.value);
      expect(
        sharing.shared,
        'https://boteparroquial.web.app/join/${settings.code.value}',
      );
      await repo.copyLink(settings);
      expect(sharing.copied, sharing.shared);
      await expectLater(
        repo.copy(
          InvitationSettings(
            code: service.code,
            enabled: false,
            requiresApproval: true,
            updatedAt: DateTime.utc(2026),
          ),
        ),
        throwsA(isA<AppFailure>()),
      );
      expect(service.removals, 0);
    },
  );

  test(
    'Solicitud evita doble envío y descarta respuestas de otra sesión',
    () async {
      final session = auth.FakeAuthRepository(auth.alice),
          members = LiveGroups(),
          service = Invitations(members);
      final container = ProviderContainer(
        overrides: [
          firebaseStartupProvider.overrideWithValue(
            FirebaseStartup.ready(auth.FakeApp()),
          ),
          authRepositoryProvider.overrideWithValue(session),
          userProfileRepositoryProvider.overrideWithValue(
            auth.FakeProfileRepository(),
          ),
          groupInvitationRepositoryProvider.overrideWithValue(
            GroupInvitationRepository(service, Sharing()),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await session.changes.close();
        await members.changes.close();
        await service.changes.close();
      });
      container.listen(joinGroupProvider, (_, _) {});
      await container.read(authStateProvider.future);
      final controller = container.read(joinGroupProvider.notifier);
      await controller.preview(service.code.value);
      service.delayedSubmit = Completer<JoinRequestStatus>();
      final first = controller.submit();
      await controller.submit();
      await Future<void>.delayed(Duration.zero);
      expect(service.submits, 1);
      service.delayedSubmit!.complete(JoinRequestStatus.pending);
      await first;
      expect(
        container.read(joinGroupProvider).result,
        JoinRequestStatus.pending,
      );
      final late = Completer<InvitationPreview>();
      service.delayedPreview = late.future;
      final request = controller.preview(service.code.value);
      session.emit(auth.bob);
      await Future<void>.delayed(Duration.zero);
      late.complete(
        InvitationPreview(
          code: service.code,
          groupName: 'Privado de otra sesión',
          currency: 'EUR',
          requiresApproval: true,
        ),
      );
      await request;
      expect(container.read(joinGroupProvider).preview, isNull);
      expect(container.read(joinGroupProvider).loading, false);
    },
  );

  testWidgets(
    'UI de invitaciones, aprobación, retirada y solicitud con texto ampliado',
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
          members = LiveGroups(),
          service = Invitations(members),
          sharing = Sharing();
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
          groupInvitationRepositoryProvider.overrideWithValue(
            GroupInvitationRepository(service, sharing),
          ),
          groupServerConfirmedProvider.overrideWith(
            (ref, id) => Stream.value(true),
          ),
          pendingMovementProvider.overrideWith((ref, id) async => null),
          personsProvider.overrideWith((ref, id) => Stream.value([])),
          movementsProvider.overrideWith((ref, id) => Stream.value([])),
          photoPresentationProvider.overrideWith(
            (ref, target) => (bytes: null, loading: false),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await session.changes.close();
        await members.changes.close();
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
        ScaffoldMessenger.of(
          tester.element(find.byType(Scaffold).last),
        ).hideCurrentSnackBar();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(text).last);
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      }

      router.go('/groups/a/invitations');
      await tester.pumpAndSettle();
      expect(find.text('Invitación desactivada'), findsOneWidget);
      await tap('Configurar invitación');
      await tap('Guardar invitación');
      expect(service.settings?.requiresApproval, true);
      // Enable explicitly, then exercise copy/share through the provider/repository service seam.
      await container
          .read(invitationControllerProvider('a').notifier)
          .configure(
            enabled: true,
            requiresApproval: true,
            original: service.settings,
          );
      await tester.pumpAndSettle();
      await tap('Copiar código');
      expect(sharing.copied, service.settings!.code.value);
      await tap('Aceptar');
      await tap('Aceptar miembro');
      expect(service.decisions, 1);
      router.go('/groups/a/members');
      await tester.pumpAndSettle();
      expect(find.text('Roberto'), findsOneWidget);
      await tap('Retirar acceso');
      await tap('Retirar acceso');
      expect(service.removals, 1);
      service.readmission = true;
      router.go('/join');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), service.code.value);
      await tap('Ver invitación');
      expect(
        find.textContaining('Tu vuelta necesita aprobación.'),
        findsOneWidget,
      );
      await tap('Solicitar entrada');
      expect(find.text('Tu solicitud está enviada'), findsOneWidget);
      expect(service.submits, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
