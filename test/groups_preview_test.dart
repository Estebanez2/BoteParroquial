import 'dart:io';
import 'dart:ui' as ui;
import 'package:bote_parroquial/app/app.dart';
import 'package:bote_parroquial/app/router.dart';
import 'package:bote_parroquial/core/firebase/firebase_bootstrap.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/auth/providers/account_lifecycle_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_deletion_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_sync_providers.dart';
import 'package:bote_parroquial/features/persons/providers/person_providers.dart';
import 'package:bote_parroquial/features/movements/providers/movement_providers.dart';
import 'package:bote_parroquial/features/photos/providers/photo_providers.dart';
import 'package:bote_parroquial/features/quotas/providers/quota_providers.dart';
import 'package:bote_parroquial/features/quotas/providers/allocation_providers.dart';
import 'package:bote_parroquial/features/reports/providers/quota_report_providers.dart';
import 'package:bote_parroquial/models/person.dart';
import 'package:bote_parroquial/models/movement.dart';
import 'package:bote_parroquial/repositories/movement_repository.dart';
import 'package:bote_parroquial/repositories/person_repository.dart';
import 'package:bote_parroquial/repositories/quota_report_repository.dart';
import 'package:bote_parroquial/features/settings/providers/appearance_providers.dart';
import 'package:bote_parroquial/models/appearance_settings.dart';
import 'package:bote_parroquial/repositories/appearance_repository.dart';
import 'support/memory_appearance.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/idle_daily_copies.dart';
import 'auth_flow_test.dart' as auth;
import 'groups_test.dart' as groups;
import 'movements_test.dart' as money;
import 'persons_test.dart' as persons;
import 'quota_reports_test.dart' as quotas;

class _PreviewMovements extends money.MemoryMovements {
  @override
  Stream<List<Movement>> watchMovements(String groupId) => super
      .watchMovements(groupId)
      .map((rows) => rows.where((m) => m.groupId == groupId).toList());
}

void main() {
  testWidgets(
    'Exporta grupos para revisión visual',
    (tester) async {
      await tester.runAsync(() async {
        for (final (family, asset) in [
          ('Manrope', 'assets/fonts/Manrope-Variable.ttf'),
          ('Newsreader', 'assets/fonts/Newsreader-Variable.ttf'),
          ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
        ]) {
          await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
        }
      });
      tester.view.physicalSize = const Size(412, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final session = auth.FakeAuthRepository(auth.alice);
      final repository = groups.FakeGroups();
      final movements = _PreviewMovements();
      final personService = persons.MemoryPersons();
      final quotaService = quotas.MemoryGroupQuotas();
      movements.current = [
        for (final entry in [
          ('one', 5250, MovementType.income),
          ('two', 2250, MovementType.withdrawal),
          ('three', 1250, MovementType.income),
        ])
          Movement(
            id: entry.$1,
            groupId: 'a',
            status: MovementStatus.active,
            input: MovementInput(
              type: entry.$3,
              amountCents: entry.$2,
              occurredAt: DateTime.utc(2026, 10, 15),
              description: 'Actividad de la comunidad',
              personId: 'p',
            ),
            createdBy: 'alice',
            createdAt: DateTime.utc(2026, 10, 15, 12),
            updatedAt: DateTime.utc(2026, 10, 15, 12),
          ),
      ];
      final people = [
        for (final entry in [
          ('p', 'Alejandro Estebanez Moreno', true),
          ('m', 'Marta García López', true),
          ('j', 'Javier Ruiz Sánchez', false),
        ])
          Person(
            id: entry.$1,
            groupId: 'a',
            displayName: entry.$2,
            notes: 'Participa en las actividades de la comunidad.',
            isActive: entry.$3,
            createdBy: 'alice',
            updatedBy: 'alice',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
      ];
      final container = ProviderContainer(
        overrides: [
          appearanceRepositoryProvider.overrideWithValue(
            AppearanceRepository(MemoryAppearance()),
          ),
          dailyCopyControllerProvider.overrideWith(IdleDailyCopies.new),
          pendingGroupDeletionsProvider.overrideWith((ref) => Stream.value([])),
          accountClosingProvider.overrideWith((ref) async => false),
          photoPresentationProvider.overrideWith(
            (ref, target) => (bytes: null, loading: false),
          ),
          personRepositoryProvider.overrideWithValue(
            PersonRepository(personService),
          ),
          quotaRulesProvider.overrideWith((ref, id) => Stream.value([])),
          allocationsProvider.overrideWith((ref, key) => Stream.value([])),
          participationPeriodsProvider.overrideWith(
            (ref, key) => Stream.value([]),
          ),
          quotaReportRepositoryProvider.overrideWithValue(
            QuotaReportRepository(quotaService),
          ),
          groupServerConfirmedProvider.overrideWith(
            (ref, groupId) => Stream.value(true),
          ),
          pendingMovementProvider.overrideWith((ref, groupId) async => null),
          firebaseStartupProvider.overrideWithValue(
            FirebaseStartup.ready(auth.FakeApp()),
          ),
          authRepositoryProvider.overrideWithValue(session),
          userProfileRepositoryProvider.overrideWithValue(
            auth.FakeProfileRepository(),
          ),
          groupRepositoryProvider.overrideWithValue(repository),
          movementsProvider.overrideWith(
            (ref, groupId) =>
                Stream.value(groupId == 'a' ? movements.current : const []),
          ),
          movementRepositoryProvider.overrideWithValue(
            MovementRepository(movements),
          ),
          personsProvider.overrideWith(
            (ref, groupId) => Stream.value(groupId == 'a' ? people : const []),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await session.changes.close();
        await repository.changes.close();
        await movements.changes.close();
        await personService.changes.close();
        await quotaService.changes.close();
      });
      final key = GlobalKey();
      final output = Directory('.dart_tool/visual_v04')
        ..createSync(recursive: true);
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: UncontrolledProviderScope(
            container: container,
            child: const BoteParroquialApp(),
          ),
        ),
      );
      for (final (name, route, dark) in [
        ('home-dark', '/', true),
        ('persons-dark', '/groups/a/persons', true),
        ('members-dark', '/groups/a/members', true),
        ('history-dark', '/groups/a/movements', true),
        ('movement-dark', '/groups/a/movements/new', true),
        ('participants-dark', '/groups/a/participants', true),
        ('reports-dark', '/groups/a/reports', true),
        ('settings-dark', '/settings/appearance', true),
      ]) {
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? ui.Brightness.dark
            : ui.Brightness.light;
        container.read(routerProvider).go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1.5);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '${output.path}/$name.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      container.read(routerProvider).go('/groups/a/persons');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Añadir persona'));
      await tester.tap(find.text('Añadir persona'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final personBoundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await personBoundary.toImage(pixelRatio: 1.5);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${output.path}/person-editor-dark.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      for (final palette in AppPalette.values) {
        for (final mode in [AppearanceMode.light, AppearanceMode.dark]) {
          await container
              .read(appearanceProvider.notifier)
              .select(palette: palette, mode: mode);
          container.read(routerProvider).go('/groups/a');
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1.5);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '${output.path}/group-${palette.name}-${mode.name}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
    },
    skip: !const bool.fromEnvironment('EXPORT_GROUP_PREVIEWS'),
  );
}
