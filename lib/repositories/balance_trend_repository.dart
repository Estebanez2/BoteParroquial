import '../core/errors/app_failure.dart';
import '../models/monthly_balance.dart';
import '../models/movement.dart';
import '../models/year_month.dart';

abstract final class BalanceTrendRepository {
  static List<MonthlyBalance> calculate(
    String groupId,
    List<Movement> movements,
    YearMonth currentMonth,
  ) {
    if (movements.any((m) => m.groupId != groupId)) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Los movimientos no corresponden a este grupo.',
      );
    }
    return List.generate(6, (index) {
      final month = currentMonth.addMonths(index - 5);
      final before = month.addMonths(1).firstDayUtc;
      final total = movements
          .where(
            (m) =>
                m.status == MovementStatus.active &&
                m.input.occurredAt.isBefore(before),
          )
          .fold<BigInt>(
            BigInt.zero,
            (sum, m) => sum + BigInt.from(m.input.signedCents),
          );
      final cents = total.toInt();
      if (BigInt.from(cents) != total) {
        throw const AppFailure(
          FailureCode.invalidData,
          'El saldo excede el intervalo admitido.',
        );
      }
      return MonthlyBalance(month, cents);
    }, growable: false);
  }
}
