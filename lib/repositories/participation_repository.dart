import '../core/errors/app_failure.dart';
import '../models/person.dart';
import '../models/participation_period.dart';
import '../models/year_month.dart';
import '../services/participation_service.dart';

class ParticipationRepository {
  const ParticipationRepository(this._service);
  final ParticipationService _service;

  static List<Person> awaitingFirstMonth(
    String groupId,
    List<Person> persons,
    List<ParticipationPeriod> periods,
  ) {
    final configured = periods
        .where((p) => p.groupId == groupId)
        .map((p) => p.personId)
        .toSet();
    return persons
        .where(
          (p) =>
              p.groupId == groupId &&
              p.isActive &&
              p.lastParticipationPeriodId == null &&
              !configured.contains(p.id),
        )
        .toList()
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
  }

  /// Each person remains an atomic, audited transaction under existing Rules.
  /// Stop on the first error; never claim an all-or-nothing bulk write.
  Future<FirstMonthSetupResult> startFirstMonths({
    required String groupId,
    required String actorUid,
    required List<Person> persons,
    required YearMonth month,
    required YearMonth currentMonth,
    required bool Function() canContinue,
  }) async {
    if (persons.isEmpty ||
        persons.map((p) => p.id).toSet().length != persons.length ||
        persons.any(
          (p) =>
              p.groupId != groupId ||
              !p.isActive ||
              p.lastParticipationPeriodId != null,
        ) ||
        month.isAfter(currentMonth)) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Revisa las personas pendientes y el primer mes seleccionado.',
      );
    }
    final completed = <String>[];
    for (final person in persons) {
      try {
        if (!canContinue()) {
          throw const AppFailure(
            FailureCode.permissionDenied,
            'Tu sesión o tus permisos han cambiado.',
          );
        }
        await change(
          groupId: groupId,
          actorUid: actorUid,
          person: person,
          previous: null,
          month: month,
          currentMonth: currentMonth,
          starting: true,
        );
        completed.add(person.id);
      } catch (error) {
        return FirstMonthSetupResult(
          List.unmodifiable(completed),
          failedName: person.displayName,
          error: error,
        );
      }
    }
    return FirstMonthSetupResult(List.unmodifiable(completed));
  }

  Stream<List<ParticipationPeriod>> watchPeriods(
    String groupId,
    String personId,
  ) => _service.watchPeriods(groupId, personId);
  Future<void> change({
    required String groupId,
    required String actorUid,
    required Person person,
    required ParticipationPeriod? previous,
    required YearMonth month,
    required YearMonth currentMonth,
    required bool starting,
  }) {
    if (person.groupId != groupId ||
        month.isAfter(currentMonth) ||
        previous?.id != person.lastParticipationPeriodId ||
        (previous != null &&
            (previous.groupId != groupId || previous.personId != person.id)) ||
        (starting
            ? (previous != null &&
                  (person.isActive ||
                      previous.lastMonthInclusive == null ||
                      month.isBefore(previous.lastMonthInclusive!)))
            : (!person.isActive ||
                  previous == null ||
                  previous.lastMonthInclusive != null ||
                  month.isBefore(previous.firstMonth)))) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Revisa el periodo: no puede solaparse, cerrar antes de su inicio ni empezar después del mes actual.',
      );
    }
    return _service.change(
      groupId,
      actorUid,
      person,
      previous,
      month,
      starting,
    );
  }
}

class FirstMonthSetupResult {
  const FirstMonthSetupResult(this.completedIds, {this.failedName, this.error});
  final List<String> completedIds;
  final String? failedName;
  final Object? error;
}
