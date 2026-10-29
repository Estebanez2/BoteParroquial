import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bote_parroquial/app/app.dart';
import 'package:bote_parroquial/app/router.dart';
import 'package:bote_parroquial/core/firebase/firebase_bootstrap.dart';
import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_sync_providers.dart';
import 'package:bote_parroquial/features/movements/providers/movement_providers.dart';
import 'package:bote_parroquial/features/persons/providers/person_providers.dart';
import 'package:bote_parroquial/features/photos/providers/photo_providers.dart';
import 'package:bote_parroquial/features/quotas/providers/allocation_providers.dart';
import 'package:bote_parroquial/features/quotas/providers/quota_providers.dart';
import 'package:bote_parroquial/models/movement.dart';
import 'package:bote_parroquial/models/year_month.dart';
import 'package:bote_parroquial/repositories/movement_repository.dart';
import 'auth_flow_test.dart' as auth;
import 'groups_test.dart' as groups;
import 'member_links_test.dart' as links;
import 'movements_test.dart' as movements;
import 'quota_allocations_test.dart' as quota;
import 'support/memory_pending_movements.dart';

void main() {
  testWidgets(
    'Devolución se confirma, corrección revisa reparto vacío y anulación restaura sin perder navegación',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1100);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final session = auth.FakeAuthRepository(auth.alice),
          membership = groups.FakeGroups();
      final service = movements.MemoryMovements()
        ..current = [quota.income('one', 10000)];
      final rows = [
        quota.allocation('one', quota.may, 2000),
        quota.allocation('one', quota.june, 2000),
      ];
      final container = ProviderContainer(
        overrides: [
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
          personsProvider.overrideWith(
            (ref, id) => Stream.value([links.person('p')]),
          ),
          movementRepositoryProvider.overrideWithValue(
            MovementRepository(service),
          ),
          pendingMovementServiceProvider.overrideWithValue(
            MemoryPendingMovements(),
          ),
          quotaMonthProvider.overrideWith((ref, id) => quota.june),
          quotaRulesProvider.overrideWith(
            (ref, id) => Stream.value(quota.rules),
          ),
          participationPeriodsProvider.overrideWith(
            (ref, key) => Stream.value(quota.periods),
          ),
          allocationsProvider.overrideWith((ref, key) => Stream.value(rows)),
          photoPresentationProvider.overrideWith(
            (ref, target) => (bytes: null, loading: false),
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
      Future<void> tap(String label) async {
        await tester.ensureVisible(find.text(label).last);
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
      }

      Future<void> money(String label, String text) async {
        final field = find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is AppMoneyField && w.label == label,
          ),
          matching: find.byType(TextFormField),
        );
        await tester.ensureVisible(field);
        await tester.enterText(field, text);
      }

      Future<void> description(String label, String text) async {
        final field = find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is AppTextField && w.label == label,
          ),
          matching: find.byType(TextFormField),
        );
        await tester.ensureVisible(field);
        await tester.enterText(field, text);
      }

      Future<void> month() async {
        final dropdown = find.byType(DropdownButtonFormField<YearMonth>).first;
        await tester.ensureVisible(dropdown);
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        final option = find.textContaining('2026-05 ·').last;
        await tester.ensureVisible(option);
        await tester.tap(option);
        await tester.pumpAndSettle();
      }

      router.go('/groups/a/refunds/one');
      await tester.pumpAndSettle();
      await month();
      await money('Cuánto devolver de este mes', '5');
      await money('Cuánto devolver de este crédito', '10');
      await description('Motivo de la devolución', 'DEMO devolución parcial');
      await tap('Revisar devolución');
      expect(service.current.length, 1);
      expect(find.text('Confirmar devolución'), findsOneWidget);
      await tap('Guardar devolución');
      expect(service.current.last.input.amountCents, 1500);
      expect(service.current.last.input.refund!.atMonth(quota.may), 500);
      final first = service.current.last;
      router.go('/groups/a/refunds/one?original=${first.id}');
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Las cantidades empiezan en cero'),
        findsOneWidget,
      );
      await month();
      await money('Cuánto devolver de este mes', '6');
      await money('Cuánto devolver de este crédito', '5');
      await description('Motivo de la corrección', 'DEMO ajustar reparto');
      await tap('Revisar devolución');
      await tap('Guardar corrección');
      expect(service.current.last.input.amountCents, 1100);
      expect(service.current[1].status, MovementStatus.corrected);
      expect(
        router.routeInformationProvider.value.uri.path,
        '/groups/a/movements',
      );
      expect(tester.takeException(), isNull);
      final current = service.current.last;
      router.go('/groups/a/movements/${current.id}/cancel');
      await tester.pumpAndSettle();
      await description('Motivo de la anulación', 'DEMO deshacer');
      await tap('Revisar anulación');
      expect(
        find.textContaining('se restaurarán conjuntamente'),
        findsOneWidget,
      );
      await tap('Anular movimiento');
      expect(service.current.last.status, MovementStatus.cancelled);
      expect(MovementRepository.balanceOf(service.current), 10000);
      expect(tester.takeException(), isNull);
    },
  );
}
