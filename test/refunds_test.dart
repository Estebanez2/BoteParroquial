import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/models/movement.dart';
import 'package:bote_parroquial/models/pending_movement.dart';
import 'package:bote_parroquial/models/refund_plan.dart';
import 'package:bote_parroquial/models/refund_source.dart';
import 'package:bote_parroquial/models/year_month.dart';
import 'package:bote_parroquial/repositories/allocation_repository.dart';
import 'package:bote_parroquial/repositories/movement_repository.dart';
import 'package:bote_parroquial/repositories/movement_submission_repository.dart';
import 'package:bote_parroquial/repositories/refund_repository.dart';
import 'package:bote_parroquial/services/file_pending_movement_service.dart';
import 'quota_allocations_test.dart' as quota;
import 'movement_recovery_test.dart' as recovery;

Movement returned(
  String id,
  RefundPlan plan, {
  MovementStatus status = MovementStatus.active,
}) => Movement(
  id: id,
  groupId: 'a',
  createdBy: 'alice',
  status: status,
  createdAt: DateTime.utc(2026, 6, 2),
  updatedAt: DateTime.utc(2026, 6, 2),
  input: MovementInput(
    type: MovementType.withdrawal,
    amountCents: plan.amountCents,
    personId: 'p',
    description: 'DEMO devolución',
    occurredAt: DateTime.utc(2026, 6, 2),
    refund: plan,
  ),
);

void main() {
  const repository = RefundRepository();
  final income = quota.income('one', 10000);
  final allocations = [
    quota.allocation('one', quota.may, 2000),
    quota.allocation('one', quota.june, 2000),
    quota.allocation('one', quota.july, 1000),
  ];
  final plan = RefundPlan(
    incomeId: 'one',
    unallocatedCents: 1000,
    parts: [
      RefundPart(month: quota.may, amountCents: 500),
      RefundPart(month: quota.june, amountCents: 1000),
    ],
  );
  test(
    'Devolución parcial descuenta pagos y crédito; anular restaura y corregir cuenta solo el sustituto',
    () {
      final active = returned('r', plan),
          s = quota.settle([income, active], allocations);
      expect(s.pendingCents, 1500);
      expect(s.allocatedThroughCurrentCents, 2500);
      expect(s.futureCreditCents, 1000);
      expect(s.unallocatedCreditCents, 4000);
      expect(s.incomes.single.allocatedCents, 5000);
      expect(s.incomes.single.paidCents, 3500);
      expect(allocations.first.amountCents, 2000);
      expect(MovementRepository.balanceOf([income, active]), 7500);
      for (final status in [
        MovementStatus.cancelled,
        MovementStatus.corrected,
      ]) {
        final restored = quota.settle([
          income,
          returned('r', plan, status: status),
        ], allocations);
        expect(restored.pendingCents, 0);
        expect(restored.unallocatedCreditCents, 5000);
      }
      final replacement = RefundPlan(
        incomeId: 'one',
        unallocatedCents: 0,
        parts: [RefundPart(month: quota.may, amountCents: 100)],
      );
      final revised = quota.settle([
        income,
        returned('r', plan, status: MovementStatus.corrected),
        returned('r2', replacement),
      ], allocations);
      expect(revised.pendingCents, 100);
      expect(revised.unallocatedCreditCents, 5000);
      expect(
        () => quota.settle([
          income,
          returned(
            'r',
            RefundPlan(incomeId: 'one', unallocatedCents: 5001, parts: []),
          ),
        ], allocations),
        throwsA(isA<AppFailure>()),
      );
    },
  );
  test(
    'Límites de devolución y revisión expresa: restaura solo el original, rechaza exceso y fecha anterior',
    () {
      final rows = [income, returned('r', plan)],
          s = quota.settle(rows, allocations);
      final source = repository.source(
        groupId: 'a',
        incomeId: 'one',
        settlement: s,
        movements: rows,
        allocations: allocations,
      );
      final correcting = repository.source(
        groupId: 'a',
        incomeId: 'one',
        originalId: 'r',
        settlement: s,
        movements: rows,
        allocations: allocations,
      );
      expect(source.months.first.availableCents, 1500);
      expect(source.unallocatedCents, 4000);
      expect(correcting.months.first.availableCents, 2000);
      expect(correcting.unallocatedCents, 5000);
      MovementInput prepare(
        Map<YearMonth, int?> parts,
        int credit, {
        DateTime? date,
      }) => repository.prepare(
        source: source,
        selected: parts,
        unallocatedCents: credit,
        occurredAt: date ?? DateTime.utc(2026, 6, 2),
        description: 'DEMO',
      );
      expect(prepare({quota.may: 500}, 1000).amountCents, 1500);
      expect(() => prepare({quota.may: 1501}, 0), throwsA(isA<AppFailure>()));
      expect(() => prepare({}, 4001), throwsA(isA<AppFailure>()));
      expect(() => prepare({}, 0), throwsA(isA<AppFailure>()));
      expect(
        () => prepare({}, 1, date: DateTime.utc(2026, 5, 31)),
        throwsA(isA<AppFailure>()),
      );
      final four = RefundPlan(
        incomeId: 'one',
        unallocatedCents: 0,
        parts: [
          for (var i = 0; i < 4; i++)
            RefundPart(month: quota.may.addMonths(i), amountCents: 1),
        ],
      );
      final far = quota.may.addMonths(4);
      expect(
        () => repository.prepare(
          source: RefundSource(
            income: income,
            original: returned('old', four),
            unallocatedCents: 1000,
            months: [RefundableMonth(month: far, availableCents: 10)],
          ),
          selected: {far: 1},
          unallocatedCents: 0,
          occurredAt: DateTime.utc(2026, 6, 2),
          description: 'DEMO',
        ),
        throwsA(isA<AppFailure>()),
      );
    },
  );
  test(
    'Reparto manual no libera dinero ya devuelto ni supera el crédito aún disponible',
    () {
      final s = quota.settle([income, returned('r', plan)], allocations),
          repo = AllocationRepository(quota.AllocationMemory());
      review(YearMonth month, int cents) => repo.review(
        groupId: 'a',
        operationId: 'op',
        actorUid: 'alice',
        movement: income,
        month: month,
        cents: cents,
        settlement: s,
        allocations: allocations,
        periods: quota.periods,
        rules: quota.rules,
      );
      expect(() => review(quota.may, 499), throwsA(isA<AppFailure>()));
      expect(review(quota.may, 500).change.amountCents, 500);
      expect(() => review(quota.july, 5001), throwsA(isA<AppFailure>()));
    },
  );
  test(
    'Journal conserva el plan al reiniciar, recupera confirmación y detecta mismo importe con otro reparto',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'bote-refund-journal-',
      );
      final service = recovery.InterruptedMovements()..current = [income];
      FilePendingMovementService storage() =>
          FilePendingMovementService(directory: () async => directory);
      MovementSubmissionRepository repo() =>
          MovementSubmissionRepository(storage(), MovementRepository(service));
      addTearDown(() async {
        await service.changes.close();
        expect(
          directory.absolute.parent.path,
          Directory.systemTemp.absolute.path,
        );
        await directory.delete(recursive: true);
      });
      final intent = PendingMovement(
        groupId: 'a',
        id: 'r',
        actorUid: 'alice',
        input: returned('r', plan).input,
      );
      await expectLater(
        repo().submit(intent, today: DateTime.utc(2026, 6, 2)),
        throwsA(isA<AppFailure>()),
      );
      final restored = (await repo().pending('alice', 'a'))!;
      expect(restored.input.refund!.sameAs(plan), true);
      expect(await repo().resolve(restored), true);
      expect(service.current.length, 2);
      final different = RefundPlan(
        incomeId: 'one',
        unallocatedCents: 1000,
        parts: [RefundPart(month: quota.july, amountCents: 1500)],
      );
      final conflict = PendingMovement(
        groupId: 'a',
        id: 'r',
        actorUid: 'alice',
        input: returned('r', different).input,
      );
      await expectLater(repo().resolve(conflict), throwsA(isA<AppFailure>()));
      final correction = PendingMovement(
        groupId: 'a',
        id: 'next',
        actorUid: 'alice',
        input: returned('next', different).input,
        original: service.current.last,
        reason: 'DEMO ajuste',
      );
      await storage().write(correction);
      final read = (await storage().read('alice', 'a'))!;
      expect(read.original!.input.refund!.sameAs(plan), true);
      expect(read.input.refund!.sameAs(different), true);
      expect(RefundPlan.fromMap(plan.toMap())!.sameAs(plan), true);
    },
  );
}
