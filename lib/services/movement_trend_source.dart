import '../models/monthly_balance.dart';
import '../models/year_month.dart';

abstract interface class MovementTrendSource {
  Future<List<MonthlyBalance>> loadBalanceTrend(
    String groupId,
    String uid,
    YearMonth currentMonth,
  );
}
