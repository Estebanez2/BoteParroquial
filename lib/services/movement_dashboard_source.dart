import '../models/movement.dart';
import '../models/movement_cash_totals.dart';

abstract interface class MovementDashboardSource {
  Stream<List<Movement>> watchRecent(String groupId);
  Stream<List<Movement>> watchQuotaSources(String groupId);
  Stream<MovementCashTotals> watchCash(
    String groupId,
    String uid,
    DateTime monthStart,
  );
  Future<void> clearCashAccount(String uid);
}
