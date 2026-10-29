import '../core/errors/app_failure.dart';
import '../models/movement.dart';
import '../models/movement_day.dart';
import '../models/movement_history_filter.dart';

/// Presentation projection: grouping keeps the existing effective-date ordering.
class MovementHistoryRepository {
  const MovementHistoryRepository();

  static DateTime _day(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  String? filterError(MovementHistoryFilter filter) {
    final from = filter.fromDate, to = filter.toDate;
    if (from != null && to != null && _day(from).isAfter(_day(to))) {
      return 'La fecha inicial debe ser anterior o igual a la final.';
    }
    return null;
  }

  void _checkGroup(String groupId, Movement movement) {
    if (movement.groupId != groupId) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'El movimiento pertenece a otro grupo.',
      );
    }
  }

  // Spanish-friendly search: ignore accents, case and extra whitespace.
  static String _normalize(String value) {
    var result = value.toLowerCase();
    const accents = 'áéíóúüñ', plain = 'aeiouun';
    for (var i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], plain[i]);
    }
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  MovementHistoryOptions options(
    String groupId,
    Iterable<Movement> movements, {
    required Map<String, String> persons,
    required Map<String, String> authors,
  }) {
    final people = {...persons}, creators = {...authors};
    for (final movement in movements) {
      _checkGroup(groupId, movement);
      final personId = movement.input.personId;
      if (personId != null) {
        people.putIfAbsent(personId, () => 'Persona no disponible');
      }
      creators.putIfAbsent(movement.createdBy, () => 'Usuario no disponible');
    }
    Map<String, String> sorted(Map<String, String> values) {
      final entries = values.entries.toList()
        ..sort((a, b) {
          final name = _normalize(a.value).compareTo(_normalize(b.value));
          return name != 0 ? name : a.key.compareTo(b.key);
        });
      return Map.fromEntries(entries);
    }

    return MovementHistoryOptions(
      persons: sorted(people),
      authors: sorted(creators),
    );
  }

  List<Movement> filter(
    String groupId,
    Iterable<Movement> movements,
    MovementHistoryFilter criteria, {
    Map<String, String> persons = const {},
    Map<String, String> authors = const {},
  }) {
    final error = filterError(criteria);
    if (error != null) throw AppFailure(FailureCode.invalidData, error);
    final words = _normalize(
      criteria.query,
    ).split(' ').where((s) => s.isNotEmpty);
    final from = criteria.fromDate, to = criteria.toDate;
    final result = <Movement>[];
    for (final movement in movements) {
      // Validate every source row, including rows that would not match filters.
      _checkGroup(groupId, movement);
      final input = movement.input, date = _day(movement.input.occurredAt);
      if (criteria.type != null && input.type != criteria.type) continue;
      if (criteria.status != null && movement.status != criteria.status) {
        continue;
      }
      if (criteria.groupOnly && input.personId != null) continue;
      if (criteria.personId != null && input.personId != criteria.personId) {
        continue;
      }
      if (criteria.authorUid != null &&
          movement.createdBy != criteria.authorUid) {
        continue;
      }
      if (from != null && date.isBefore(_day(from))) continue;
      if (to != null && date.isAfter(_day(to))) continue;
      final person = input.personId == null
          ? 'El grupo'
          : persons[input.personId] ?? 'Persona no disponible';
      final text = _normalize(
        [
          person,
          authors[movement.createdBy] ?? 'Usuario no disponible',
          input.description,
          movement.cancellationReason ?? '',
          movement.correctionReason ?? '',
        ].join(' '),
      );
      if (!words.every(text.contains)) continue;
      result.add(movement);
    }
    // Keep the same effective-date ordering as the existing full history.
    result.sort((a, b) {
      final date = b.input.occurredAt.compareTo(a.input.occurredAt);
      if (date != 0) return date;
      final created = b.createdAt.compareTo(a.createdAt);
      return created != 0 ? created : a.id.compareTo(b.id);
    });
    return List.unmodifiable(result);
  }

  List<MovementDay> groupByDay(String groupId, Iterable<Movement> movements) {
    final days = <DateTime, List<Movement>>{};
    for (final movement in movements) {
      _checkGroup(groupId, movement);
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
