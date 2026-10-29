import '../core/errors/app_failure.dart';

class MovementCashTotals {
  const MovementCashTotals({
    required this.groupId,
    required this.monthStart,
    required this.incomeCents,
    required this.withdrawalCents,
    required this.monthIncomeCents,
    required this.monthWithdrawalCents,
    required this.confirmedAt,
    this.cached = false,
  });
  final String groupId;
  final DateTime monthStart, confirmedAt;
  final int incomeCents,
      withdrawalCents,
      monthIncomeCents,
      monthWithdrawalCents;
  final bool cached;
  void validate(String expectedGroup, DateTime expectedMonth) {
    if (groupId != expectedGroup ||
        monthStart != expectedMonth ||
        [
          incomeCents,
          withdrawalCents,
          monthIncomeCents,
          monthWithdrawalCents,
        ].any((v) => v < 0) ||
        monthIncomeCents > incomeCents ||
        monthWithdrawalCents > withdrawalCents) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Los agregados de caja no son coherentes.',
      );
    }
    final balance = BigInt.from(incomeCents) - BigInt.from(withdrawalCents);
    if (BigInt.from(balance.toInt()) != balance) {
      throw const AppFailure(
        FailureCode.invalidData,
        'El saldo supera el intervalo admitido.',
      );
    }
  }
}
