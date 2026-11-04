import 'dart:async';
import 'dart:convert';
import 'package:bote_parroquial/app/app.dart';
import 'package:bote_parroquial/app/router.dart';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/core/firebase/firebase_bootstrap.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/auth/providers/profile_editor_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_management_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/groups/providers/audit_history_providers.dart';
import 'package:bote_parroquial/repositories/audit_history_repository.dart';
import 'package:bote_parroquial/features/groups/presentation/group_editor_screen.dart';
import 'package:bote_parroquial/features/groups/presentation/group_audit_screen.dart';
import 'package:bote_parroquial/features/groups/providers/group_sync_providers.dart';
import 'package:bote_parroquial/features/movements/providers/movement_providers.dart';
import 'package:bote_parroquial/features/persons/providers/person_providers.dart';
import 'package:bote_parroquial/features/quotas/providers/quota_providers.dart';
import 'package:bote_parroquial/features/quotas/providers/allocation_providers.dart';
import 'package:bote_parroquial/features/photos/providers/photo_providers.dart';
import 'package:bote_parroquial/features/reports/providers/report_providers.dart';
import 'package:bote_parroquial/models/auth_user.dart';
import 'package:bote_parroquial/models/economic_report.dart';
import 'package:bote_parroquial/models/group.dart';
import 'package:bote_parroquial/models/group_input.dart';
import 'package:bote_parroquial/models/group_member.dart';
import 'package:bote_parroquial/models/movement.dart';
import 'package:bote_parroquial/models/user_profile.dart';
import 'package:bote_parroquial/repositories/economic_report_repository.dart';
import 'package:bote_parroquial/repositories/movement_repository.dart';
import 'package:bote_parroquial/repositories/csv_export_repository.dart';
import 'package:bote_parroquial/repositories/group_management_repository.dart';
import 'package:bote_parroquial/repositories/profile_editor_repository.dart';
import 'package:bote_parroquial/repositories/user_profile_repository.dart';
import 'package:bote_parroquial/services/group_management_service.dart';
import 'package:bote_parroquial/services/file_sharing_service.dart';
import 'package:bote_parroquial/services/profile_editor_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/idle_daily_copies.dart';
import 'auth_flow_test.dart' as auth;
import 'dashboard_test.dart' as dashboard;
import 'groups_test.dart' as groups;
import 'movement_history_test.dart' as history;
import 'audit_history_test.dart' as audit;
import 'movements_test.dart' as money;

class ManagedGroups extends groups.FakeGroups
    implements GroupManagementService {
  final saved = <String, Group>{};
  final updates = StreamController<Group>.broadcast();
  GroupInput? lastCreation;
  int writes = 0;
  @override
  String newId() => 'created-group';
  @override
  Stream<Group?> watchGroup(String groupId) async* {
    if (saved.containsKey(groupId)) {
      yield saved[groupId];
    } else {
      yield await super.watchGroup(groupId).first;
    }
    yield* updates.stream.where((group) => group.id == groupId);
  }

  @override
  Future<void> create(
    String id,
    String uid,
    String displayName,
    GroupInput input,
  ) async {
    lastCreation = input;
    writes++;
    saved[id] = Group(
      id: id,
      name: input.name,
      description: input.description,
      currency: input.currency,
      timeZone: input.timeZone,
      isActive: true,
      createdBy: uid,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    current = [
      ...current,
      GroupMember(
        groupId: id,
        uid: uid,
        displayName: displayName,
        role: GroupRole.owner,
        isActive: true,
        personId: input.createOwnerPerson ? 'owner' : null,
        joinedAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    ];
    changes.add(current);
  }

  @override
  Future<void> update(
    Group group,
    String uid,
    String name,
    String description,
  ) async {
    writes++;
    final result = Group(
      id: group.id,
      name: name,
      description: description,
      currency: group.currency,
      timeZone: group.timeZone,
      isActive: true,
      createdBy: group.createdBy,
      createdAt: group.createdAt,
      updatedAt: DateTime.utc(2026, 10, 17),
    );
    saved[group.id] = result;
    updates.add(result);
  }
}

class Profiles implements UserProfileRepository, ProfileEditorService {
  String name = 'Alicia';
  @override
  Future<UserProfile> ensureProfile(AuthUser user) async => UserProfile(
    uid: user.uid,
    displayName: name,
    email: user.email,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  @override
  Future<void> rename(UserProfile original, String name) async {
    this.name = name;
  }
}

class FileSharing extends Fake implements FileSharingService {}

void main() {
  test(
    'CSV conserva céntimos/estados y neutraliza fórmulas sin conceder permisos',
    () {
      final repository = CsvExportRepository(FileSharing());
      final group = Group(
        id: 'a',
        name: '=SUM(1;2)',
        currency: 'EUR',
        timeZone: 'Europe/Madrid',
        isActive: true,
        createdBy: 'alice',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final owner = groups.member('a', 'alice', role: GroupRole.owner);
      final rows = [
        history.row('active'),
        history.row('cancelled', status: MovementStatus.cancelled),
      ];
      final file = repository.build(
        'alice',
        group,
        owner,
        [dashboard.person('p', false)],
        rows,
        {'alice': 'Nombre "con comillas"'},
        const ReportSelection(year: 2026, month: 10),
      );
      final text = utf8.decode(file.bytes);
      expect(file.bytes.take(3), [0xef, 0xbb, 0xbf]);
      expect(text, contains('"\'=SUM(1;2)"'));
      expect(text, contains('"Nombre ""con comillas"""'));
      expect(text, contains('"2050";"2050"'));
      expect(text, contains('"2050";"0"'));
      expect(file.name.endsWith('.csv'), true);
      expect(
        () => repository.build(
          'alice',
          group,
          groups.member('a', 'alice'),
          [],
          rows,
          {},
          const ReportSelection(year: 2026, month: 10),
        ),
        throwsA(isA<AppFailure>()),
      );
    },
  );
  test(
    'Informes: saldos, límites de mes/trimestre/año, estados e aislamiento',
    () {
      const repo = EconomicReportRepository();
      final rows = [
        history.row('september', day: 0),
        history.row('october'),
        history.row('expense', type: MovementType.withdrawal, personId: null),
        history.row('cancelled', status: MovementStatus.cancelled),
        history.row('corrected', status: MovementStatus.corrected),
      ];
      final persons = [dashboard.person('p', false)];
      final month = repo.summarize(
        'a',
        rows,
        persons,
        const ReportSelection(year: 2026, month: 10),
      );
      expect(month.openingCents, 2050);
      expect(month.incomeCents, 2050);
      expect(month.withdrawalCents, 2050);
      expect(month.closingCents, 2050);
      expect(month.activeMovementsCount, 2);
      expect(month.persons.first.isActive, isFalse);
      final quarter = repo.summarize(
        'a',
        rows,
        persons,
        const ReportSelection(
          year: 2026,
          month: 11,
          period: ReportPeriod.quarter,
        ),
      );
      expect(quarter.start, DateTime.utc(2026, 10));
      expect(quarter.endExclusive, DateTime.utc(2027));
      expect(quarter.months.length, 3);
      final year = repo.summarize(
        'a',
        rows,
        persons,
        const ReportSelection(year: 2026, month: 12, period: ReportPeriod.year),
      );
      expect(year.incomeCents, 4100);
      expect(year.closingCents, month.closingCents);
      expect(year.months.length, 12);
      final summary = repo.personSummary('a', persons.single, rows);
      expect(summary.incomeCents, 4100);
      expect(summary.movements.length, 4);
      expect(
        () => repo.summarize(
          'b',
          rows,
          persons,
          const ReportSelection(year: 2026, month: 10),
        ),
        throwsA(isA<AppFailure>()),
      );
      expect(
        () => repo.personSummary('b', persons.single, rows),
        throwsA(isA<AppFailure>()),
      );
      expect(
        repo
            .summarize('a', [], [], const ReportSelection(year: 2026, month: 1))
            .closingCents,
        0,
      );
    },
  );

  test(
    'Grupos y perfil validan nombres, moneda y cuenta antes de escribir',
    () async {
      final service = ManagedGroups(), profiles = Profiles();
      addTearDown(() async {
        await service.changes.close();
        await service.updates.close();
      });
      final repository = GroupManagementRepository(service);
      await repository.create(
        'new',
        'alice',
        ' Alicia ',
        const GroupInput(
          name: ' Grupo ',
          description: ' Texto ',
          currency: 'EUR',
          timeZone: 'Europe/Madrid',
          createOwnerPerson: false,
        ),
      );
      expect(service.lastCreation?.name, 'Grupo');
      expect(service.lastCreation?.description, 'Texto');
      expect(service.lastCreation?.createOwnerPerson, false);
      expect(
        () => repository.create(
          'bad',
          'alice',
          'Alicia',
          const GroupInput(
            name: ' ',
            description: '',
            currency: 'EUR',
            timeZone: 'Europe/Madrid',
            createOwnerPerson: true,
          ),
        ),
        throwsA(isA<AppFailure>()),
      );
      final profile = await profiles.ensureProfile(auth.alice);
      expect(
        () => ProfileEditorRepository(
          profiles,
        ).rename('other', profile, 'Nombre'),
        throwsA(isA<AppFailure>()),
      );
      expect(service.writes, 1);
    },
  );

  testWidgets(
    'Grupos, informes, ficha, auditoría y nombre de perfil integrados',
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
          service = ManagedGroups(),
          profiles = Profiles(),
          auditLog = audit.MemoryAudit()..events = [];
      final cashSource = money.MemoryMovements();
      final container = ProviderContainer(
        overrides: [
          dailyCopyControllerProvider.overrideWith(IdleDailyCopies.new),
          movementRepositoryProvider.overrideWithValue(
            MovementRepository(cashSource),
          ),
          firebaseStartupProvider.overrideWithValue(
            FirebaseStartup.ready(auth.FakeApp()),
          ),
          authRepositoryProvider.overrideWithValue(session),
          userProfileRepositoryProvider.overrideWithValue(profiles),
          profileEditorRepositoryProvider.overrideWithValue(
            ProfileEditorRepository(profiles),
          ),
          groupRepositoryProvider.overrideWithValue(service),
          groupManagementRepositoryProvider.overrideWithValue(
            GroupManagementRepository(service),
          ),
          auditHistoryRepositoryProvider.overrideWithValue(
            AuditHistoryRepository(auditLog),
          ),
          groupServerConfirmedProvider.overrideWith(
            (ref, id) => Stream.value(true),
          ),
          pendingMovementProvider.overrideWith((ref, id) async => null),
          quotaRulesProvider.overrideWith((ref, id) => Stream.value([])),
          allocationsProvider.overrideWith((ref, key) => Stream.value([])),
          participationPeriodsProvider.overrideWith(
            (ref, key) => Stream.value([]),
          ),
          personsProvider.overrideWith(
            (ref, id) =>
                Stream.value(id == 'a' ? [dashboard.person('p', false)] : []),
          ),
          movementsProvider.overrideWith(
            (ref, id) => Stream.value(id == 'a' ? [history.row('income')] : []),
          ),
          photoPresentationProvider.overrideWith(
            (ref, target) => (bytes: null, loading: false),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await session.changes.close();
        await service.changes.close();
        await service.updates.close();
        await auditLog.changes.close();
        await cashSource.changes.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BoteParroquialApp(),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tap(String text) async {
        ScaffoldMessenger.of(
          tester.element(find.byType(Scaffold).last),
        ).hideCurrentSnackBar();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(text).last);
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      }

      final router = container.read(routerProvider);
      await tester.tap(find.byTooltip('Añadir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crear un nuevo grupo'));
      await tester.pumpAndSettle();
      expect(find.byType(GroupEditorScreen), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Mi grupo');
      await tap('Crear mi grupo');
      expect(service.lastCreation?.createOwnerPerson, true);
      expect(service.saved['created-group']?.name, 'Mi grupo');
      expect(find.text('Mi grupo'), findsOneWidget);
      await tap('Gestionar este espacio');
      await tap('Editar grupo');
      expect(find.text('Un grupo con\nnombre propio.'), findsNothing);
      expect(find.text('LA IDENTIDAD DE TU ESPACIO'), findsNothing);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Nombre editado',
      );
      await tap('Guardar grupo');
      expect(service.saved['created-group']?.name, 'Nombre editado');
      await tap('Gestionar este espacio');
      await tap('Historial administrativo');
      expect(find.byType(GroupAuditScreen), findsOneWidget);
      expect(find.text('Aquí empieza la trazabilidad'), findsOneWidget);
      router.go('/groups/a/reports');
      await tester.pumpAndSettle();
      container
          .read(reportSelectionProvider('a').notifier)
          .select(year: 2026, month: 10);
      await tester.pumpAndSettle();
      expect(
        container.read(economicReportProvider('a')).requireValue.incomeCents,
        2050,
      );
      final annual = find.widgetWithText(TextButton, 'Año');
      await tester.ensureVisible(annual);
      await tester.tap(annual);
      await tester.pumpAndSettle();
      expect(
        container.read(economicReportProvider('a')).requireValue.months.length,
        12,
      );
      await tap('Ver ficha');
      expect(find.text('Su historial económico'), findsOneWidget);
      expect(find.text('Ana'), findsWidgets);
      router.go('/profile');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Mi nombre propio');
      await tap('Guardar mi nombre');
      expect(profiles.name, 'Mi nombre propio');
      expect(service.writes, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
