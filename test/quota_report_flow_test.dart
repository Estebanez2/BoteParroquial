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
import 'package:bote_parroquial/features/quotas/providers/quota_providers.dart';
import 'package:bote_parroquial/features/reports/providers/quota_report_providers.dart';
import 'package:bote_parroquial/features/reports/providers/report_providers.dart';
import 'package:bote_parroquial/models/economic_report.dart';
import 'package:bote_parroquial/repositories/quota_report_repository.dart';
import 'package:bote_parroquial/repositories/group_calendar_repository.dart';
import 'package:bote_parroquial/features/reports/providers/report_comparison_providers.dart';
import 'package:bote_parroquial/services/group_clock_service.dart';
import 'auth_flow_test.dart' as auth;
import 'groups_test.dart' as groups;
import 'quota_allocations_test.dart' as quota;
import 'quota_reports_test.dart' as fixtures;

class _ReportClock implements GroupClockService {
  @override
  DateTime today(String timeZone) => DateTime.utc(2026, 6, 15);
}

void main() {
  testWidgets(
    'Dashboard e informes comparten lecturas, separan futuro y reaccionan a datos/acceso en ambos temas',
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
          membership = groups.FakeGroups();
      final service = fixtures.MemoryGroupQuotas()
        ..periods = fixtures.periods
        ..allocations = List.of(fixtures.allocations);
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
          pendingMovementProvider.overrideWith((ref, id) async => null),
          personsProvider.overrideWith(
            (ref, id) => Stream.value(
              fixtures.people.where((p) => p.groupId == id).toList(),
            ),
          ),
          movementsProvider.overrideWith(
            (ref, id) => Stream.value(
              fixtures.money.where((m) => m.groupId == id).toList(),
            ),
          ),
          quotaRulesProvider.overrideWith(
            (ref, id) => Stream.value(
              quota.rules.where((r) => r.groupId == id).toList(),
            ),
          ),
          quotaMonthProvider.overrideWith((ref, id) => quota.june),
          groupCalendarRepositoryProvider.overrideWithValue(
            GroupCalendarRepository(_ReportClock()),
          ),
          quotaReportRepositoryProvider.overrideWithValue(
            QuotaReportRepository(service),
          ),
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
      Future<void> pumpApp(ThemeMode mode) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: BoteParroquialApp(themeMode: mode),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpApp(ThemeMode.dark);
      final router = container.read(routerProvider);
      router.go('/groups/a');
      await tester.pumpAndSettle();
      expect(find.text('Las cuotas de tu comunidad'), findsOneWidget);
      expect(find.text('Por cubrir hasta 2026-06'), findsOneWidget);
      expect(
        container
            .read(dashboardQuotaReportProvider('a'))
            .requireValue
            .accumulated
            .totals
            .pendingCents,
        1000,
      );
      Future<void> tap(String text) async {
        await tester.ensureVisible(find.text(text).last);
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      }

      await tap('Ver informe de cuotas');
      container
          .read(reportSelectionProvider('a').notifier)
          .select(period: ReportPeriod.year, year: 2026, month: 6);
      await tester.pumpAndSettle();
      expect(find.text('Lo que cubren las aportaciones'), findsOneWidget);
      expect(find.text('Meses futuros · Previsión'), findsOneWidget);
      expect(service.periodReads, 1);
      expect(service.allocationReads, 1);
      expect(
        container
            .read(quotaReportProvider('a'))
            .requireValue
            .forecast
            .totals
            .pendingCents,
        11000,
      );
      await tap('Mes a mes');
      expect(tester.takeException(), isNull);
      await tap('Beatriz');
      expect(find.text('Ver ficha de Beatriz'), findsOneWidget);
      expect(find.text('Inactiva'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await pumpApp(ThemeMode.light);
      expect(
        Theme.of(
          tester.element(find.text('Lo que cubren las aportaciones')),
        ).brightness,
        Brightness.light,
      );
      expect(tester.takeException(), isNull);
      container
          .read(reportSelectionProvider('a').notifier)
          .select(period: ReportPeriod.month, year: 2026, month: 5);
      await tester.pumpAndSettle();
      await tap('Comparar con el periodo anterior');
      expect(find.text('Una mirada al periodo anterior'), findsOneWidget);
      final comparison = container
          .read(reportComparisonProvider('a'))
          .requireValue!;
      expect(comparison.income.current, 2000);
      expect(comparison.income.previous, 0);
      expect(comparison.paidQuota.current, 4500);
      expect(find.text('Sin porcentaje comparable'), findsWidgets);
      expect(service.periodReads, 1);
      expect(service.allocationReads, 1);
      expect(tester.takeException(), isNull);
      await pumpApp(ThemeMode.dark);
      expect(find.text('Una mirada al periodo anterior'), findsOneWidget);
      expect(tester.takeException(), isNull);
      container
          .read(reportSelectionProvider('a').notifier)
          .select(period: ReportPeriod.year, year: 2026, month: 6);
      await tester.pumpAndSettle();
      final partialComparison = container
          .read(reportComparisonProvider('a'))
          .requireValue!;
      expect(partialComparison.isPartial, true);
      expect(
        partialComparison.currentWindow.endExclusive,
        DateTime.utc(2026, 6, 16),
      );
      expect(
        partialComparison.previousWindow.endExclusive,
        DateTime.utc(2025, 6, 16),
      );
      // Changing a shared allocation updates the summary without opening more queries.
      service.allocations = [
        fixtures.allocation('one', 'p', quota.may, 3000),
        fixtures.allocation('one', 'p', quota.june, 1500),
        fixtures.allocation('one', 'p', quota.july, 500),
        fixtures.allocations.last,
      ];
      service.changes.add(null);
      await tester.pumpAndSettle();
      expect(
        container
            .read(quotaReportProvider('a'))
            .requireValue
            .elapsed
            .totals
            .pendingCents,
        500,
      );
      expect(service.periodReads, 1);
      expect(service.allocationReads, 1);
      membership.current = [];
      membership.changes.add([]);
      await tester.pumpAndSettle();
      expect(find.text('Lo que cubren las aportaciones'), findsNothing);
      expect(find.text('Una mirada al periodo anterior'), findsNothing);
      expect(find.text('Este espacio no está disponible'), findsWidgets);
      expect(
        await container.read(groupQuotaPeriodsProvider('a').future),
        isEmpty,
      );
      expect(
        await container.read(groupQuotaAllocationsProvider('a').future),
        isEmpty,
      );
      router.go('/');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
