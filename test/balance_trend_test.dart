import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/models/movement.dart';
import 'package:bote_parroquial/models/year_month.dart';
import 'package:bote_parroquial/repositories/balance_trend_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Movement movement(
  String id,
  int year,
  int month,
  int cents, {
  MovementType type = MovementType.income,
  MovementStatus status = MovementStatus.active,
  String group = 'g',
}) => Movement(
  id: id,
  groupId: group,
  input: MovementInput(
    type: type,
    amountCents: cents,
    occurredAt: DateTime.utc(year, month, 1),
    description: 'DEMO',
  ),
  status: status,
  createdBy: 'u',
  createdAt: DateTime.utc(year, month),
  updatedAt: DateTime.utc(year, month),
);
void main() {
  test(
    'Seis cierres incluyen saldo anterior, retiros y correcciones sin mezclar grupos ni perder céntimos',
    () {
      final result = BalanceTrendRepository.calculate('g', [
        movement('base', 2025, 1, 10000),
        movement('june', 2026, 6, 3000),
        movement('july', 2026, 7, 2000, type: MovementType.withdrawal),
        movement('old', 2026, 8, 9999, status: MovementStatus.corrected),
        movement('replacement', 2026, 8, 500),
        movement('cancelled', 2026, 9, 9999, status: MovementStatus.cancelled),
        movement('nov', 2026, 11, 20000, type: MovementType.withdrawal),
        movement('future', 2026, 12, 100000),
      ], YearMonth(2026, 11));
      expect(result.map((p) => p.month.toString()), [
        '2026-06',
        '2026-07',
        '2026-08',
        '2026-09',
        '2026-10',
        '2026-11',
      ]);
      expect(result.map((p) => p.balanceCents), [
        13000,
        11000,
        11500,
        11500,
        11500,
        -8500,
      ]);
      expect(
        BalanceTrendRepository.calculate(
          'g',
          [],
          YearMonth(2026, 11),
        ).map((p) => p.balanceCents),
        everyElement(0),
      );
      expect(
        BalanceTrendRepository.calculate('g', [
          movement('exact', 2025, 1, 9007199254740993),
        ], YearMonth(2026, 11)).last.balanceCents,
        9007199254740993,
      );
      expect(
        () => BalanceTrendRepository.calculate('g', [
          movement('foreign', 2026, 1, 1, group: 'other'),
        ], YearMonth(2026, 11)),
        throwsA(isA<AppFailure>()),
      );
    },
  );
}
