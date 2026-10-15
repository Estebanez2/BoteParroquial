import 'movement.dart';

class MovementDay {
  MovementDay({required this.date, required Iterable<Movement> movements})
    : movements = List.unmodifiable(movements);
  final DateTime date;
  final List<Movement> movements;
}
