import 'dart:async';
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
import 'package:bote_parroquial/features/quotas/providers/quota_providers.dart';
import 'package:bote_parroquial/features/quotas/providers/allocation_providers.dart';
import 'package:bote_parroquial/models/person.dart';
import 'package:bote_parroquial/models/group_member.dart';
import 'package:bote_parroquial/models/participation_period.dart';
import 'package:bote_parroquial/models/quota_rule.dart';
import 'package:bote_parroquial/models/year_month.dart';
import 'package:bote_parroquial/repositories/group_calendar_repository.dart';
import 'package:bote_parroquial/repositories/quota_repository.dart';
import 'package:bote_parroquial/repositories/participation_repository.dart';
import 'package:bote_parroquial/services/group_clock_service.dart';
import 'package:bote_parroquial/services/quota_service.dart';
import 'package:bote_parroquial/services/participation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'auth_flow_test.dart' as auth;
import 'group_invitations_test.dart' as invitation;
import 'member_links_test.dart' as links;

final oct = YearMonth(2026, 10),
    sep = YearMonth(2026, 9),
    nov = YearMonth(2026, 11);

class Quotas implements QuotaService {
  final changes = StreamController<void>.broadcast();
  final rules = <QuotaRule>[];
  final versions = <QuotaRule>[];
  int writes = 0;
  @override
  Stream<List<QuotaRule>> watchRules(String groupId) async* {
    yield List.of(rules);
    yield* changes.stream.map((_) => List.of(rules));
  }

  @override
  Stream<List<QuotaRule>> watchVersions(String groupId, String id) async* {
    yield versions.where((r) => r.id == id).toList();
    yield* changes.stream.map(
      (_) => versions.where((r) => r.id == id).toList(),
    );
  }

  @override
  Future<void> saveRule(
    String groupId,
    String uid,
    YearMonth month,
    int cents,
    QuotaRule? old,
  ) async {
    writes++;
    final next = QuotaRule(
      id: '${month.ordinal}',
      groupId: groupId,
      effectiveFrom: month,
      monthlyFeeCents: cents,
      revision: (old?.revision ?? 0) + 1,
    );
    rules.removeWhere((r) => r.id == next.id);
    rules.add(next);
    versions.add(next);
    changes.add(null);
  }
}

class Participation implements ParticipationService {
  final changes = StreamController<void>.broadcast();
  final periods = <ParticipationPeriod>[];
  int writes = 0;
  Person person = links.person('persona');
  Stream<List<Person>> watchPeople() async* {
    yield [person];
    yield* changes.stream.map((_) => [person]);
  }

  @override
  Stream<List<ParticipationPeriod>> watchPeriods(
    String groupId,
    String id,
  ) async* {
    yield List.of(periods);
    yield* changes.stream.map((_) => List.of(periods));
  }

  @override
  Future<void> change(
    String groupId,
    String uid,
    Person target,
    ParticipationPeriod? previous,
    YearMonth month,
    bool starting,
  ) async {
    writes++;
    final period = ParticipationPeriod(
      id: starting ? 'period-$writes' : previous!.id,
      groupId: groupId,
      personId: target.id,
      firstMonth: starting ? month : previous!.firstMonth,
      lastMonthInclusive: starting ? null : month,
    );
    if (!starting) periods.removeWhere((p) => p.id == period.id);
    periods.add(period);
    person = Person(
      id: target.id,
      groupId: groupId,
      displayName: target.displayName,
      isActive: starting,
      createdBy: target.createdBy,
      updatedBy: uid,
      createdAt: target.createdAt,
      updatedAt: target.updatedAt.add(const Duration(seconds: 1)),
      lastParticipationPeriodId: period.id,
    );
    changes.add(null);
  }
}

void main() {
  test(
    'Guardar cuotas protege meses actuales y valida ámbito; participación exige mes explícito y coherente',
    () async {
      final q = Quotas(),
          p = Participation(),
          repo = QuotaRepository(q),
          participation = ParticipationRepository(p);
      addTearDown(q.changes.close);
      addTearDown(p.changes.close);
      await repo.saveRule(
        groupId: 'a',
        actorUid: 'alice',
        month: sep,
        currentMonth: oct,
        cents: 2050,
        rules: [],
      );
      expect(
        () => repo.saveRule(
          groupId: 'a',
          actorUid: 'alice',
          month: oct,
          currentMonth: oct,
          cents: 2500,
          rules: q.rules,
        ),
        throwsA(isA<AppFailure>()),
      );
      await repo.saveRule(
        groupId: 'a',
        actorUid: 'alice',
        month: nov,
        currentMonth: oct,
        cents: 0,
        rules: q.rules,
      );
      await repo.saveRule(
        groupId: 'a',
        actorUid: 'alice',
        month: nov,
        currentMonth: oct,
        cents: 2500,
        rules: q.rules,
      );
      expect(q.writes, 3);
      expect(q.versions.where((r) => r.effectiveFrom == nov).length, 2);
      expect(QuotaRepository.atMonth(q.rules, oct)?.monthlyFeeCents, 2050);
      expect(
        () => participation.change(
          groupId: 'b',
          actorUid: 'alice',
          person: p.person,
          previous: null,
          month: sep,
          currentMonth: oct,
          starting: true,
        ),
        throwsA(isA<AppFailure>()),
      );
      await participation.change(
        groupId: 'a',
        actorUid: 'alice',
        person: p.person,
        previous: null,
        month: sep,
        currentMonth: oct,
        starting: true,
      );
      expect(
        () => participation.change(
          groupId: 'a',
          actorUid: 'alice',
          person: p.person,
          previous: p.periods.last,
          month: YearMonth(2026, 8),
          currentMonth: oct,
          starting: false,
        ),
        throwsA(isA<AppFailure>()),
      );
      await participation.change(
        groupId: 'a',
        actorUid: 'alice',
        person: p.person,
        previous: p.periods.last,
        month: sep,
        currentMonth: oct,
        starting: false,
      );
      await participation.change(
        groupId: 'a',
        actorUid: 'alice',
        person: p.person,
        previous: p.periods.last,
        month: oct,
        currentMonth: oct,
        starting: true,
      );
      expect(p.periods.length, 2);
      expect(p.person.isActive, true);
      await participation.change(
        groupId: 'a',
        actorUid: 'alice',
        person: p.person,
        previous: p.periods.last,
        month: oct,
        currentMonth: oct,
        starting: false,
      );
      await participation.change(
        groupId: 'a',
        actorUid: 'alice',
        person: p.person,
        previous: p.periods.last,
        month: oct,
        currentMonth: oct,
        starting: true,
      );
      expect(p.person.isActive, true);
      expect(p.periods.length, 3);
    },
  );
  testWidgets(
    'Cuota confirmada, cambio futuro cero y primer mes de persona en pantalla pequeña',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1000);
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
          groups = invitation.LiveGroups()
            ..current = [links.member('alice', role: GroupRole.owner)];
      final q = Quotas(), p = Participation();
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
          quotaRepositoryProvider.overrideWithValue(QuotaRepository(q)),
          participationRepositoryProvider.overrideWithValue(
            ParticipationRepository(p),
          ),
          groupCalendarRepositoryProvider.overrideWithValue(
            GroupCalendarRepository(
              TimeZoneGroupClockService(now: () => DateTime.utc(2026, 10, 19)),
            ),
          ),
          personsProvider.overrideWith((ref, id) => p.watchPeople()),
          movementsProvider.overrideWith((ref, id) => Stream.value([])),
          allocationsProvider.overrideWith((ref, key) => Stream.value([])),
          groupServerConfirmedProvider.overrideWith(
            (ref, id) => Stream.value(true),
          ),
          pendingMovementProvider.overrideWith((ref, id) async => null),
          photoPresentationProvider.overrideWith(
            (ref, t) => (bytes: null, loading: false),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await session.changes.close();
        await groups.changes.close();
        await q.changes.close();
        await p.changes.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BoteParroquialApp(),
        ),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/groups/a/quotas');
      await tester.pumpAndSettle();
      Future<void> tap(String text) async {
        await tester.ensureVisible(find.text(text).last);
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      }

      await tester.enterText(find.byType(TextFormField).first, '20,50');
      await tap('Revisar cuota');
      expect(q.writes, 0);
      await tap('Guardar cuota');
      expect(q.writes, 1);
      ScaffoldMessenger.of(
        tester.element(find.byType(Scaffold).last),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byType(DropdownButtonFormField<int>).first,
      );
      await tester.tap(find.byType(DropdownButtonFormField<int>).first);
      await tester.pumpAndSettle();
      await tap('noviembre');
      await tester.enterText(find.byType(TextFormField).first, '0');
      await tap('Revisar cuota');
      await tap('Guardar cuota');
      expect(q.writes, 2);
      expect(
        q.rules.singleWhere((r) => r.effectiveFrom == nov).monthlyFeeCents,
        0,
      );
      container.read(routerProvider).go('/groups/a/persons/persona');
      await tester.pumpAndSettle();
      await tap('Elegir primer mes');
      await tap('Revisar primer mes');
      expect(p.writes, 0);
      await tap('Confirmar primer mes');
      expect(p.writes, 1);
      expect(p.periods.single.firstMonth, oct);
      expect(tester.takeException(), isNull);
    },
  );
}
