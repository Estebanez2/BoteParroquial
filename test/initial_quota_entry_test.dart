import 'dart:io';
import 'package:bote_parroquial/app/app.dart';
import 'package:bote_parroquial/app/router.dart';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/core/firebase/firebase_bootstrap.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_sync_providers.dart';
import 'package:bote_parroquial/features/movements/providers/movement_providers.dart';
import 'package:bote_parroquial/features/persons/providers/person_providers.dart';
import 'package:bote_parroquial/features/quotas/providers/allocation_providers.dart';
import 'package:bote_parroquial/features/quotas/providers/quota_providers.dart';
import 'package:bote_parroquial/models/initial_quota_assignment.dart';
import 'package:bote_parroquial/models/movement.dart';
import 'package:bote_parroquial/models/participation_period.dart';
import 'package:bote_parroquial/models/pending_movement.dart';
import 'package:bote_parroquial/models/person.dart';
import 'package:bote_parroquial/models/quota_rule.dart';
import 'package:bote_parroquial/models/year_month.dart';
import 'package:bote_parroquial/repositories/initial_quota_repository.dart';
import 'package:bote_parroquial/repositories/movement_repository.dart';
import 'package:bote_parroquial/repositories/movement_submission_repository.dart';
import 'package:bote_parroquial/repositories/quota_settlement_repository.dart';
import 'package:bote_parroquial/services/file_pending_movement_service.dart';
import 'package:bote_parroquial/services/initial_quota_movement_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'auth_flow_test.dart' as auth;
import 'groups_test.dart' as groups;
import 'movements_test.dart' as money;
import 'support/idle_daily_copies.dart';
import 'support/memory_pending_movements.dart';

class AtomicMemory extends money.MemoryMovements
    implements InitialQuotaMovementService {
  final applied = <String, InitialQuotaAssignment>{};
  bool loseAcknowledgement = false;
  @override
  Future<void> saveWithInitialQuota(
    String groupId,
    String id,
    String actorUid,
    MovementInput input,
    InitialQuotaAssignment assignment,
  ) async {
    await super.save(groupId, id, actorUid, input);
    applied[id] = assignment;
    if (loseAcknowledgement) {
      throw const AppFailure(FailureCode.network, 'DEMO respuesta perdida');
    }
  }

  @override
  Future<bool> initialQuotaApplied(
    String groupId,
    String id,
    String actorUid,
    InitialQuotaAssignment assignment,
  ) async => applied[id] == assignment;
}

final month = YearMonth(2026, 11);
final stages = [
  ParticipationPeriod(
    id: 'stage',
    groupId: 'a',
    personId: 'p',
    firstMonth: YearMonth(2026, 10),
  ),
];
final rules = [
  QuotaRule(
    id: 'fee',
    groupId: 'a',
    effectiveFrom: YearMonth(2026, 10),
    monthlyFeeCents: 200,
  ),
];
final settlement = const QuotaSettlementRepository().summarize(
  groupId: 'a',
  personId: 'p',
  currentMonth: month,
  rules: rules,
  periods: stages,
  movements: [],
  allocations: [],
);
final input = MovementInput(
  type: MovementType.income,
  amountCents: 300,
  occurredAt: DateTime.utc(2026, 11, 1),
  description: 'DEMO',
  personId: 'p',
);

void main() {
  test(
    'Reparto inicial explícito y journal v3 recuperan ambos sin duplicar el ingreso',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'bote-initial-quota-',
      );
      final service = AtomicMemory()..loseAcknowledgement = true;
      final storage = FilePendingMovementService(
        directory: () async => directory,
      );
      final movements = MovementRepository(service);
      final repo = MovementSubmissionRepository(storage, movements);
      final choice = InitialQuotaRepository.review(
        groupId: 'a',
        personId: 'p',
        month: month,
        cents: 100,
        incomeCents: 300,
        periods: stages,
        rules: rules,
        settlement: settlement,
      ).assignment;
      final pending = PendingMovement(
        groupId: 'a',
        actorUid: 'alice',
        id: 'new',
        input: input,
        initialQuota: choice,
      );
      try {
        expect(
          () => InitialQuotaRepository.review(
            groupId: 'a',
            personId: 'p',
            month: month,
            cents: 301,
            incomeCents: 300,
            periods: stages,
            rules: rules,
            settlement: settlement,
          ),
          throwsA(isA<AppFailure>()),
        );
        expect(
          () => InitialQuotaRepository.review(
            groupId: 'a',
            personId: 'p',
            month: YearMonth(2026, 9),
            cents: 100,
            incomeCents: 300,
            periods: stages,
            rules: rules,
            settlement: settlement,
          ),
          throwsA(isA<AppFailure>()),
        );
        expect(
          InitialQuotaRepository.review(
            groupId: 'a',
            personId: 'p',
            month: month,
            cents: 300,
            incomeCents: 300,
            periods: stages,
            rules: rules,
            settlement: settlement,
          ).overpaymentCents,
          100,
        );
        await expectLater(repo.submit(pending), throwsA(isA<AppFailure>()));
        final reopened = MovementSubmissionRepository(
          FilePendingMovementService(directory: () async => directory),
          movements,
        );
        final restored = await reopened.pending('alice', 'a');
        expect(restored!.initialQuota, choice);
        service.applied.clear();
        await expectLater(
          reopened.resolve(restored),
          throwsA(isA<AppFailure>()),
        );
        expect(await reopened.pending('alice', 'a'), isNotNull);
        service.applied['new'] = choice;
        expect(await reopened.resolve(restored), true);
        expect(service.current.length, 1);
        expect(await reopened.pending('alice', 'a'), isNull);
      } finally {
        await service.changes.close();
        expect(
          directory.absolute.parent.path,
          Directory.systemTemp.absolute.path,
        );
        await directory.delete(recursive: true);
      }
    },
  );

  testWidgets(
    'Formulario compacto permite elegir mes e importe y guarda ingreso/cuota desde la misma pantalla',
    (tester) async {
      tester.view.physicalSize = const Size(412, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = auth.FakeAuthRepository(auth.alice),
          membership = groups.FakeGroups(),
          service = AtomicMemory();
      final person = Person(
        id: 'p',
        groupId: 'a',
        displayName: 'Persona DEMO',
        isActive: true,
        createdBy: 'alice',
        updatedBy: 'alice',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final container = ProviderContainer(
        overrides: [
          dailyCopyControllerProvider.overrideWith(IdleDailyCopies.new),
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
          personsProvider.overrideWith((ref, id) => Stream.value([person])),
          movementRepositoryProvider.overrideWithValue(
            MovementRepository(service),
          ),
          pendingMovementServiceProvider.overrideWithValue(
            MemoryPendingMovements(),
          ),
          quotaMonthProvider.overrideWith((ref, id) => month),
          quotaRulesProvider.overrideWith((ref, id) => Stream.value(rules)),
          participationPeriodsProvider.overrideWith(
            (ref, key) => Stream.value(stages),
          ),
          personQuotaSettlementProvider.overrideWith(
            (ref, key) => AsyncData(settlement),
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
      container.read(routerProvider).go('/groups/a/movements/new');
      await tester.pumpAndSettle();
      Future<void> tap(String label) async {
        await tester.ensureVisible(find.text(label).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
      }

      expect(find.text('Revisar y guardar').hitTestable(), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '3,00');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tap('Persona DEMO');
      await tap('Elegir cuota (opcional)');
      await tester.enterText(find.byType(TextFormField).last, '1,00');
      await tap('Usar este mes');
      expect(find.text('Cuota 2026-11 · 1,00 €'), findsOneWidget);
      await tap('Revisar y guardar');
      expect(find.text('Guardar ingreso y cuota'), findsOneWidget);
      expect(service.current, isEmpty);
      await tap('Guardar ambos');
      expect(service.current.single.input.amountCents, 300);
      expect(service.applied.values.single.amountCents, 100);
      expect(service.applied.values.single.month, month);
    },
  );
}
