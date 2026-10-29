import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bote_parroquial/app/app.dart';
import 'package:bote_parroquial/app/router.dart';
import 'package:bote_parroquial/core/firebase/firebase_bootstrap.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_sync_providers.dart';
import 'package:bote_parroquial/features/movements/providers/movement_providers.dart';
import 'package:bote_parroquial/features/persons/providers/person_providers.dart';
import 'package:bote_parroquial/features/photos/providers/photo_providers.dart';
import 'package:bote_parroquial/features/quotas/providers/allocation_providers.dart';
import 'package:bote_parroquial/features/quotas/providers/quota_providers.dart';
import 'package:bote_parroquial/models/group_member.dart';
import 'package:bote_parroquial/models/quota_allocation.dart';
import 'package:bote_parroquial/models/year_month.dart';
import 'package:bote_parroquial/repositories/allocation_repository.dart';
import 'auth_flow_test.dart' as auth;
import 'group_invitations_test.dart' as invitations;
import 'member_links_test.dart' as links;
import 'quota_allocations_test.dart' as quota;

class LiveAllocations extends quota.AllocationMemory {
  final changes = StreamController<void>.broadcast();
  final rows = <QuotaAllocation>[];
  int writes = 0;
  @override
  Stream<List<QuotaAllocation>> watchAllocations(
    String groupId,
    String personId,
  ) async* {
    yield List.of(rows);
    yield* changes.stream.map((_) => List.of(rows));
  }

  @override
  Future<void> change(
    String groupId,
    String actorUid,
    AllocationChange change,
  ) async {
    writes++;
    rows.removeWhere(
      (a) => a.movementId == change.movement.id && a.month == change.month,
    );
    rows.add(
      QuotaAllocation(
        id: '${change.movement.id}_${change.month.ordinal}',
        groupId: groupId,
        movementId: change.movement.id,
        personId: 'p',
        month: change.month,
        amountCents: change.amountCents,
        revision: (change.previous?.revision ?? 0) + 1,
        participationPeriodId: change.participationPeriodId,
      ),
    );
    changes.add(null);
  }
}

void main() {
  testWidgets(
    'Reparto confirmado y sobrepago advertido; ficha accesible en ambos temas',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1100);
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
          groups = invitations.LiveGroups()
            ..current = [links.member('alice', role: GroupRole.owner)];
      final data = LiveAllocations();
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
          groupServerConfirmedProvider.overrideWith(
            (ref, id) => Stream.value(true),
          ),
          pendingMovementProvider.overrideWith((ref, id) async => null),
          quotaMonthProvider.overrideWith((ref, id) => YearMonth(2026, 6)),
          quotaRulesProvider.overrideWith(
            (ref, id) => Stream.value(quota.rules),
          ),
          participationPeriodsProvider.overrideWith(
            (ref, key) => Stream.value(quota.periods),
          ),
          personsProvider.overrideWith(
            (ref, id) => Stream.value([links.person('p')]),
          ),
          movementsProvider.overrideWith(
            (ref, id) => Stream.value([quota.income('one', 5000)]),
          ),
          allocationRepositoryProvider.overrideWithValue(
            AllocationRepository(data),
          ),
          photoPresentationProvider.overrideWith(
            (ref, target) => (bytes: null, loading: false),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await session.changes.close();
        await groups.changes.close();
        await data.changes.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BoteParroquialApp(),
        ),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/groups/a/movements/one/allocations');
      await tester.pumpAndSettle();
      Future<void> tap(String text) async {
        await tester.ensureVisible(find.text(text).last);
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      }

      expect(find.text('Disponible para repartir'), findsOneWidget);
      await tester.ensureVisible(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, '30');
      await tap('Revisar este mes');
      expect(data.writes, 0);
      expect(find.textContaining('sobrepago de'), findsOneWidget);
      await tap('Guardar este mes');
      expect(data.writes, 1);
      expect(data.rows.single.amountCents, 3000);
      container.read(routerProvider).go('/groups/a/persons/p');
      await tester.pumpAndSettle();
      expect(find.text('Lo que queda por cubrir'), findsOneWidget);
      expect(find.textContaining('2026-06 · Sobrepago'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Same affected UI under the light palette, preserving text scale and reduced motion.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BoteParroquialApp(themeMode: ThemeMode.light),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        Theme.of(
          tester.element(find.text('Lo que queda por cubrir')),
        ).brightness,
        Brightness.light,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
