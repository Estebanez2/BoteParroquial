import 'package:flutter_test/flutter_test.dart';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/models/movement.dart';
import 'package:bote_parroquial/models/participation_period.dart';
import 'package:bote_parroquial/models/quota_allocation.dart';
import 'package:bote_parroquial/models/quota_rule.dart';
import 'package:bote_parroquial/models/quota_settlement.dart';
import 'package:bote_parroquial/models/year_month.dart';
import 'package:bote_parroquial/repositories/allocation_repository.dart';
import 'package:bote_parroquial/repositories/quota_settlement_repository.dart';
import 'package:bote_parroquial/services/allocation_service.dart';

final may = YearMonth(2026, 5),
    june = YearMonth(2026, 6),
    july = YearMonth(2026, 7);
final rules = [
  QuotaRule(
    id: 'price',
    groupId: 'a',
    effectiveFrom: may,
    monthlyFeeCents: 2000,
  ),
];
final periods = [
  ParticipationPeriod(
    id: 'stage',
    groupId: 'a',
    personId: 'p',
    firstMonth: may,
  ),
];
Movement income(
  String id,
  int cents, {
  MovementStatus status = MovementStatus.active,
  String group = 'a',
}) => Movement(
  id: id,
  groupId: group,
  status: status,
  createdBy: 'owner',
  createdAt: DateTime.utc(2026, 6, 1),
  updatedAt: DateTime.utc(2026, 6, 1),
  input: MovementInput(
    type: MovementType.income,
    amountCents: cents,
    personId: 'p',
    occurredAt: DateTime.utc(2026, 6, 1),
    description: 'DEMO',
  ),
);
QuotaAllocation allocation(String source, YearMonth month, int cents) =>
    QuotaAllocation(
      id: '${source}_${month.ordinal}',
      groupId: 'a',
      movementId: source,
      personId: 'p',
      month: month,
      amountCents: cents,
      revision: 1,
      participationPeriodId: 'stage',
    );
PersonQuotaSettlement settle(
  List<Movement> movements,
  List<QuotaAllocation> allocations, {
  List<QuotaRule>? prices,
  List<ParticipationPeriod>? stages,
}) => const QuotaSettlementRepository().summarize(
  groupId: 'a',
  personId: 'p',
  currentMonth: june,
  rules: prices ?? rules,
  periods: stages ?? periods,
  movements: movements,
  allocations: allocations,
);

class AllocationMemory implements AllocationService {
  @override
  String newOperationId(String groupId) => 'op';
  @override
  Stream<List<QuotaAllocation>> watchAllocations(
    String groupId,
    String personId,
  ) => Stream.value([]);
  @override
  Future<void> change(
    String groupId,
    String actorUid,
    AllocationChange change,
  ) async {}
}

void main() {
  test(
    'Propone atrasos, parcial y hasta doce meses futuros; el sobrante no paga cuotas',
    () {
      final source = income('one', 5000), projection = settle([source], []);
      final proposal = const QuotaSettlementRepository().propose(
        projection,
        source,
        [],
      );
      expect(projection.pendingCents, 4000);
      expect(projection.unallocatedCreditCents, 5000);
      expect(proposal.map((s) => s.month), [may, june, july]);
      expect(proposal.map((s) => s.amountCents), [2000, 2000, 1000]);
      final paid = settle(
        [source],
        [
          allocation('one', may, 2000),
          allocation('one', june, 2000),
          allocation('one', july, 1000),
        ],
      );
      expect(paid.pendingCents, 0);
      expect(paid.futureCreditCents, 1000);
      expect(paid.unallocatedCreditCents, 0);
      expect(
        paid.months.firstWhere((m) => m.month == july).state,
        QuotaPaymentState.partial,
      );
      final large = income('large', 50000);
      final far = allocation('large', YearMonth(2028, 1), 1);
      final limited = const QuotaSettlementRepository().propose(
        settle([large], [far]),
        large,
        [far],
      );
      expect(limited.last.month, YearMonth(2027, 6));
      expect(
        limited.length,
        14,
      ); // Two current/past plus twelve future, not a product cap.
    },
  );
  test(
    'Sobrepago no compensa otro mes; anular/corregir deja de pagar y el sustituto no hereda',
    () {
      final rows = [
        allocation('one', may, 3000),
        allocation('one', june, 1000),
        allocation('one', july, 1000),
        allocation('two', july, 2000),
      ];
      final result = settle([income('one', 5000), income('two', 4000)], rows);
      expect(result.pendingCents, 1000);
      expect(result.differenceCents, 0);
      expect(result.futureCreditCents, 3000);
      expect(result.unallocatedCreditCents, 2000);
      expect(result.months.first.state, QuotaPaymentState.overpaid);
      for (final status in [
        MovementStatus.cancelled,
        MovementStatus.corrected,
      ]) {
        final changed = settle([
          income('one', 5000, status: status),
          income('two', 4000),
          income('replacement', 5000),
        ], rows);
        expect(changed.pendingCents, 4000);
        expect(changed.futureCreditCents, 2000);
        expect(changed.unallocatedCreditCents, 7000);
      }
    },
  );
  test(
    'Configuración incompleta no se transforma en cero deuda; rechaza cruces y reparto excesivo',
    () {
      final source = income('one', 5000);
      for (final result in [
        settle([source], [], prices: []),
        settle([source], [], stages: []),
      ]) {
        expect(result.isComplete, false);
        expect(result.pendingCents, isNull);
        expect(result.differenceCents, isNull);
        expect(
          const QuotaSettlementRepository().propose(result, source, []),
          isEmpty,
        );
      }
      final zero = settle(
        [source],
        [],
        prices: [
          QuotaRule(
            id: 'zero',
            groupId: 'a',
            effectiveFrom: may,
            monthlyFeeCents: 0,
          ),
        ],
      );
      expect(zero.pendingCents, 0);
      expect(zero.months.first.state, QuotaPaymentState.suspended);
      for (final rows in [
        [allocation('one', may, 5001)],
        [allocation('one', may, 2000), allocation('one', may, 1000)],
        [allocation('unknown', may, 1)],
      ]) {
        expect(() => settle([source], rows), throwsA(isA<AppFailure>()));
      }
      expect(
        () => settle([income('one', 5000, group: 'b')], []),
        throwsA(isA<AppFailure>()),
      );
    },
  );
  test(
    'Revisión permite exceso explícito, libera a cero y protege límites y participación',
    () {
      final repo = AllocationRepository(AllocationMemory()),
          source = income('one', 5000);
      AllocationReview review(
        int cents, {
        YearMonth? month,
        List<QuotaAllocation> rows = const [],
      }) => repo.review(
        groupId: 'a',
        operationId: 'op',
        actorUid: 'owner',
        movement: source,
        month: month ?? may,
        cents: cents,
        settlement: settle([source], rows),
        allocations: rows,
        periods: periods,
        rules: rules,
      );
      expect(review(3000).overpaymentCents, 1000);
      expect(() => review(5001), throwsA(isA<AppFailure>()));
      expect(() => review(-1), throwsA(isA<AppFailure>()));
      expect(
        () => review(1, month: YearMonth(2026, 4)),
        throwsA(isA<AppFailure>()),
      );
      final released = review(0, rows: [allocation('one', may, 2000)]);
      expect(released.change.previous?.amountCents, 2000);
      expect(review(3000, month: YearMonth(2028, 1)).expectedCents, 2000);
    },
  );
}
