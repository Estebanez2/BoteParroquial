import 'dart:async';
import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/persons/providers/person_providers.dart';
import 'package:bote_parroquial/features/quotas/presentation/first_month_setup.dart';
import 'package:bote_parroquial/features/quotas/providers/quota_providers.dart';
import 'package:bote_parroquial/features/reports/providers/quota_report_providers.dart';
import 'package:bote_parroquial/models/auth_user.dart';
import 'package:bote_parroquial/models/participation_period.dart';
import 'package:bote_parroquial/models/person.dart';
import 'package:bote_parroquial/models/year_month.dart';
import 'package:bote_parroquial/repositories/participation_repository.dart';
import 'package:bote_parroquial/services/participation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Person person(
  String id, {
  bool active = true,
  String group = 'g',
  String? period,
}) => Person(
  id: id,
  groupId: group,
  displayName: 'Persona $id',
  isActive: active,
  lastParticipationPeriodId: period,
  createdBy: 'owner',
  updatedBy: 'owner',
  createdAt: DateTime.utc(2026, 11),
  updatedAt: DateTime.utc(2026, 11),
);

class Periods implements ParticipationService {
  final writes = <String>[];
  final periods = <ParticipationPeriod>[];
  final changed = StreamController<void>.broadcast();
  String? fail;
  @override
  Stream<List<ParticipationPeriod>> watchPeriods(
    String groupId,
    String personId,
  ) => Stream.value(periods);
  @override
  Future<void> change(
    String groupId,
    String uid,
    Person person,
    ParticipationPeriod? previous,
    YearMonth month,
    bool starting,
  ) async {
    if (person.id == fail) throw StateError('Sin conexión de prueba');
    writes.add(person.id);
    periods.add(
      ParticipationPeriod(
        id: 'period-${person.id}',
        groupId: groupId,
        personId: person.id,
        firstMonth: month,
      ),
    );
    changed.add(null);
  }
}

void main() {
  final november = YearMonth(2026, 11);
  test(
    'Solo primeros meses pendientes: no otras cuentas, inactivos ni historia existente; corte parcial explícito',
    () async {
      final service = Periods()..fail = 'b';
      addTearDown(service.changed.close);
      final repo = ParticipationRepository(service);
      final candidates = ParticipationRepository.awaitingFirstMonth(
        'g',
        [
          person('a'),
          person('b'),
          person('c'),
          person('inactive', active: false),
          person('foreign', group: 'other'),
          person('configured', period: 'old'),
          person('history'),
        ],
        [
          ParticipationPeriod(
            id: 'old',
            groupId: 'g',
            personId: 'history',
            firstMonth: november,
          ),
        ],
      );
      expect(candidates.map((p) => p.id), ['a', 'b', 'c']);
      final result = await repo.startFirstMonths(
        groupId: 'g',
        actorUid: 'owner',
        persons: candidates,
        month: november,
        currentMonth: november,
        canContinue: () => true,
      );
      expect(result.completedIds, ['a']);
      expect(result.failedName, 'Persona b');
      expect(result.error, isNotNull);
      expect(service.writes, ['a']);
      final denied = await repo.startFirstMonths(
        groupId: 'g',
        actorUid: 'owner',
        persons: [person('c')],
        month: november,
        currentMonth: november,
        canContinue: () => false,
      );
      expect(denied.completedIds, isEmpty);
      expect(service.writes, ['a']);
    },
  );
  testWidgets(
    'Bloque visible, selección múltiple, confirmación y guardado sin visitar fichas',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = Periods();
      addTearDown(service.changed.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthUser(uid: 'owner')),
            ),
            canManagePersonsProvider.overrideWith((ref, id) => true),
            personsProvider.overrideWith(
              (ref, id) => Stream.value([person('a'), person('b')]),
            ),
            quotaMonthProvider.overrideWith((ref, id) => november),
            participationRepositoryProvider.overrideWithValue(
              ParticipationRepository(service),
            ),
            groupQuotaPeriodsProvider.overrideWith(
              (ref, id) => (() async* {
                yield List<ParticipationPeriod>.of(service.periods);
                yield* service.changed.stream.map(
                  (_) => List<ParticipationPeriod>.of(service.periods),
                );
              })(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Consumer(
              builder: (context, ref, _) {
                ref.watch(authStateProvider);
                return const AppScaffold(
                  child: FirstMonthSetupPanel(groupId: 'g'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 personas por completar'), findsOneWidget);
      await tester.tap(find.text('Completar primer mes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Seleccionar todas'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Revisar selección (2)'));
      await tester.tap(find.text('Revisar selección (2)'));
      await tester.pumpAndSettle();
      expect(service.writes, isEmpty);
      await tester.tap(find.text('Guardar primeros meses'));
      await tester.pumpAndSettle();
      expect(service.writes, ['a', 'b']);
      expect(service.periods.every((p) => p.firstMonth == november), isTrue);
      expect(
        find.text(
          'Todas las personas activas tienen su primer mes configurado.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
