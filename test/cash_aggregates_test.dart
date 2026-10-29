import 'dart:async';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/dashboard/providers/dashboard_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/movements/providers/movement_providers.dart';
import 'package:bote_parroquial/features/persons/providers/person_providers.dart';
import 'package:bote_parroquial/features/quotas/providers/quota_providers.dart';
import 'package:bote_parroquial/models/auth_user.dart';
import 'package:bote_parroquial/models/dashboard_summary.dart';
import 'package:bote_parroquial/models/group.dart';
import 'package:bote_parroquial/models/group_member.dart';
import 'package:bote_parroquial/models/movement.dart';
import 'package:bote_parroquial/models/movement_cash_totals.dart';
import 'package:bote_parroquial/models/year_month.dart';
import 'package:bote_parroquial/repositories/movement_repository.dart';
import 'package:bote_parroquial/services/firestore_cash_aggregate_service.dart';
import 'package:bote_parroquial/services/movement_dashboard_source.dart';
import 'package:bote_parroquial/services/movement_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Source extends Fake implements MovementService, MovementDashboardSource {
  int fullReads = 0;
  @override
  Stream<List<Movement>> watchMovements(String groupId) {
    fullReads++;
    throw StateError('Full history is not needed');
  }

  @override
  Stream<List<Movement>> watchRecent(String groupId) => Stream.value([]);
  @override
  Stream<MovementCashTotals> watchCash(
    String groupId,
    String uid,
    DateTime monthStart,
  ) => Stream.value(
    MovementCashTotals(
      groupId: groupId,
      monthStart: monthStart,
      incomeCents: 10001,
      withdrawalCents: 2500,
      monthIncomeCents: 2001,
      monthWithdrawalCents: 500,
      confirmedAt: DateTime.utc(2026, 10, 20),
    ),
  );
}

void main() {
  test(
    'Céntimos REST conservan int64 y rechazan double, desbordamiento y totales incoherentes',
    () {
      expect(
        FirestoreCashAggregateService.decodeInteger({
          'integerValue': '9007199254740993',
        }),
        9007199254740993,
      );
      for (final value in [
        {'doubleValue': 2050.0},
        {'integerValue': '9223372036854775808'},
        {'integerValue': '-1'},
      ]) {
        expect(
          () => FirestoreCashAggregateService.decodeInteger(value),
          throwsA(isA<AppFailure>()),
        );
      }
      final month = DateTime.utc(2026, 10),
          invalid = MovementCashTotals(
            groupId: 'a',
            monthStart: DateTime.utc(2026, 10),
            incomeCents: 100,
            withdrawalCents: 0,
            monthIncomeCents: 101,
            monthWithdrawalCents: 0,
            confirmedAt: DateTime.utc(2026),
          );
      expect(() => invalid.validate('a', month), throwsA(isA<AppFailure>()));
    },
  );
  test(
    'Dashboard usa agregados y actividad acotada sin solicitar todo el historial',
    () async {
      final source = _Source(), month = DateTime.utc(2026, 10);
      final group = Group(
        id: 'a',
        name: 'DEMO',
        currency: 'EUR',
        timeZone: 'Europe/Madrid',
        isActive: true,
        createdBy: 'alice',
        createdAt: month,
        updatedAt: month,
      );
      final member = GroupMember(
        groupId: 'a',
        uid: 'alice',
        displayName: 'Ana',
        role: GroupRole.owner,
        isActive: true,
        joinedAt: month,
        updatedAt: month,
      );
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthUser(uid: 'alice')),
          ),
          groupProvider('a').overrideWith((ref) => Stream.value(group)),
          currentMembershipProvider('a').overrideWith((ref) => member),
          quotaMonthProvider('a').overrideWith((ref) => YearMonth(2026, 10)),
          personsProvider('a').overrideWith((ref) => Stream.value([])),
          movementRepositoryProvider.overrideWithValue(
            MovementRepository(source),
          ),
        ],
      );
      addTearDown(container.dispose);
      final ready = Completer<DashboardSummary>();
      container.listen(dashboardProvider('a'), (_, next) {
        final value = next.asData?.value;
        if (value != null && !ready.isCompleted) ready.complete(value);
      }, fireImmediately: true);
      final result = await ready.future.timeout(const Duration(seconds: 5));
      expect(result.balanceCents, 7501);
      expect(result.incomeCents, 10001);
      expect(source.fullReads, 0);
    },
  );
}
