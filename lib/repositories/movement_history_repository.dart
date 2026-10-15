import '../core/errors/app_failure.dart';
import '../models/movement.dart';
import '../models/movement_day.dart';

/// Presentation projection: grouping keeps the existing effective-date ordering.
class MovementHistoryRepository {
  const MovementHistoryRepository();
  List<MovementDay> groupByDay(String groupId, Iterable<Movement> movements) {
    final days = <DateTime, List<Movement>>{};
    for (final movement in movements) {
      if (movement.groupId != groupId) {
        throw const AppFailure(
          FailureCode.permissionDenied,
          'El movimiento pertenece a otro grupo.',
        );
      }
      final date = movement.input.occurredAt;
      days
          .putIfAbsent(DateTime.utc(date.year, date.month, date.day), () => [])
          .add(movement);
    }
    final dates = days.keys.toList()..sort((a, b) => b.compareTo(a));
    return List.unmodifiable([
      for (final date in dates)
        MovementDay(date: date, movements: days[date] ?? const []),
    ]);
  }
}
