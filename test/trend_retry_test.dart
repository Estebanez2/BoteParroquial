import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/dashboard/presentation/balance_trend_panel.dart';
import 'package:bote_parroquial/features/dashboard/providers/dashboard_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/movements/providers/movement_providers.dart';
import 'package:bote_parroquial/features/quotas/providers/quota_providers.dart';
import 'package:bote_parroquial/models/auth_user.dart';
import 'package:bote_parroquial/models/group.dart';
import 'package:bote_parroquial/models/group_member.dart';
import 'package:bote_parroquial/models/monthly_balance.dart';
import 'package:bote_parroquial/models/movement_cash_totals.dart';
import 'package:bote_parroquial/models/year_month.dart';
import 'package:bote_parroquial/repositories/movement_repository.dart';
import 'package:bote_parroquial/services/movement_service.dart';
import 'package:bote_parroquial/services/movement_trend_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/idle_daily_copies.dart';

class _Trend extends Fake implements MovementService, MovementTrendSource {
  int calls = 0;
  @override
  Future<List<MonthlyBalance>> loadBalanceTrend(
    String groupId,
    String uid,
    YearMonth month,
  ) async {
    calls++;
    return List.generate(
      6,
      (i) => MonthlyBalance(month.addMonths(i - 5), 1200),
    );
  }
}

void main() {
  testWidgets(
    'Actualizar gráfica recupera también la caja tras límite de consultas',
    (tester) async {
      final date = DateTime.utc(2026, 11), source = _Trend();
      var cashReads = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyCopyControllerProvider.overrideWith(IdleDailyCopies.new),
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthUser(uid: 'alice')),
            ),
            groupProvider('a').overrideWith(
              (ref) => Stream.value(
                Group(
                  id: 'a',
                  name: 'Prueba',
                  currency: 'EUR',
                  timeZone: 'Europe/Madrid',
                  isActive: true,
                  createdBy: 'alice',
                  createdAt: date,
                  updatedAt: date,
                ),
              ),
            ),
            currentMembershipProvider('a').overrideWith(
              (ref) => GroupMember(
                groupId: 'a',
                uid: 'alice',
                displayName: 'Alice',
                role: GroupRole.owner,
                isActive: true,
                joinedAt: date,
                updatedAt: date,
              ),
            ),
            quotaMonthProvider('a').overrideWith((ref) => YearMonth(2026, 11)),
            movementRepositoryProvider.overrideWithValue(
              MovementRepository(source),
            ),
            dashboardCashProvider('a').overrideWith((ref) {
              cashReads++;
              if (cashReads == 1) {
                return Stream.error(
                  const AppFailure(
                    FailureCode.resourceExhausted,
                    'Límite alcanzado',
                  ),
                );
              }
              return Stream.value(
                MovementCashTotals(
                  groupId: 'a',
                  monthStart: date,
                  incomeCents: 1200,
                  withdrawalCents: 0,
                  monthIncomeCents: 0,
                  monthWithdrawalCents: 0,
                  confirmedAt: date,
                ),
              );
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: BalanceTrendPanel(groupId: 'a', currency: 'EUR'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Límite alcanzado'), findsOneWidget);
      await tester.tap(find.text('Actualizar gráfica'));
      await tester.pumpAndSettle();
      expect(find.byType(AppLineChart), findsOneWidget);
      expect(cashReads, 2);
      expect(source.calls, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
