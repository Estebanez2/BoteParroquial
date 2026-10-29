import '../core/errors/app_failure.dart';
import '../models/economic_report.dart';
import '../models/movement.dart';
import '../models/person.dart';
import 'movement_history_repository.dart';

class EconomicReportRepository {
  const EconomicReportRepository();
  int _add(int a, int b) {
    final exact = BigInt.from(a) + BigInt.from(b);
    final result = exact.toInt();
    if (BigInt.from(result) != exact) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Los importes del informe superan el intervalo admitido.',
      );
    }
    return result;
  }

  void _scope(
    String groupId,
    Iterable<Movement> movements,
    Iterable<Person> persons,
  ) {
    if (movements.any((m) => m.groupId != groupId) ||
        persons.any((p) => p.groupId != groupId)) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'Los datos pertenecen a otro grupo.',
      );
    }
  }

  EconomicReport summarize(
    String groupId,
    List<Movement> movements,
    List<Person> persons,
    ReportSelection selection, {
    DateTime? untilExclusive,
  }) {
    _scope(groupId, movements, persons);
    if (selection.year < 2000 ||
        selection.year > 2100 ||
        selection.month < 1 ||
        selection.month > 12) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Selecciona un periodo válido.',
      );
    }
    final month = selection.startMonth, length = selection.monthCount;
    final start = DateTime.utc(selection.year, month);
    final fullEnd = DateTime.utc(selection.year, month + length);
    final end = untilExclusive ?? fullEnd;
    if (!end.isUtc ||
        !end.isAfter(start) ||
        end.isAfter(fullEnd) ||
        end != DateTime.utc(end.year, end.month, end.day)) {
      throw const AppFailure(
        FailureCode.invalidData,
        'El tramo del informe no es válido.',
      );
    }
    var opening = 0, income = 0, withdrawal = 0, count = 0;
    final months = <int, List<int>>{
      for (var i = 0; i < length; i++) month + i: [0, 0],
    };
    final byPerson = <String?, List<int>>{};
    for (final movement in movements) {
      if (movement.status != MovementStatus.active) continue;
      final day = movement.input.occurredAt;
      if (day.isBefore(start)) {
        opening = _add(opening, movement.input.signedCents);
        continue;
      }
      if (!day.isBefore(end)) continue;
      count++;
      final isIncome = movement.input.type == MovementType.income;
      final index = isIncome ? 0 : 1, amount = movement.input.amountCents;
      if (isIncome) {
        income = _add(income, amount);
      } else {
        withdrawal = _add(withdrawal, amount);
      }
      months[day.month]![index] = _add(months[day.month]![index], amount);
      final own = byPerson.putIfAbsent(movement.input.personId, () => [0, 0]);
      own[index] = _add(own[index], amount);
    }
    final names = {for (final person in persons) person.id: person};
    final contributions =
        [
          for (final entry in byPerson.entries)
            PersonEconomics(
              personId: entry.key,
              name: entry.key == null
                  ? 'El grupo'
                  : names[entry.key]?.displayName ?? 'Persona no disponible',
              isActive: names[entry.key]?.isActive ?? false,
              incomeCents: entry.value[0],
              withdrawalCents: entry.value[1],
            ),
        ]..sort((a, b) {
          final amount = b.incomeCents.compareTo(a.incomeCents);
          return amount != 0
              ? amount
              : (a.personId ?? '').compareTo(b.personId ?? '');
        });
    // Validate the derived closing balance too, before any UI reads it.
    _add(_add(opening, income), -withdrawal);
    return EconomicReport(
      start: start,
      endExclusive: end,
      openingCents: opening,
      incomeCents: income,
      withdrawalCents: withdrawal,
      activeMovementsCount: count,
      persons: List.unmodifiable(contributions),
      months: List.unmodifiable([
        for (final entry in months.entries)
          MonthEconomics(
            month: DateTime.utc(selection.year, entry.key),
            incomeCents: entry.value[0],
            withdrawalCents: entry.value[1],
          ),
      ]),
    );
  }

  PersonFinancialSummary personSummary(
    String groupId,
    Person person,
    List<Movement> movements,
  ) {
    _scope(groupId, movements, [person]);
    final own = movements
        .where((m) => m.input.personId == person.id)
        .toList(growable: false);
    final ordered = const MovementHistoryRepository().groupByDay(groupId, own);
    final rows = List<Movement>.unmodifiable([
      for (final day in ordered) ...day.movements,
    ]);
    var income = 0, withdrawal = 0;
    for (final movement in rows) {
      if (movement.status != MovementStatus.active) continue;
      if (movement.input.type == MovementType.income) {
        income += movement.input.amountCents;
      } else {
        withdrawal += movement.input.amountCents;
      }
    }
    return PersonFinancialSummary(
      person: person,
      incomeCents: income,
      withdrawalCents: withdrawal,
      movements: rows,
    );
  }
}
