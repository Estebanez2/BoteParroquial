import '../core/errors/app_failure.dart';
import '../models/person.dart';
import '../models/participation_period.dart';
import '../models/year_month.dart';
import '../services/participation_service.dart';

class ParticipationRepository {
  const ParticipationRepository(this._service);
  final ParticipationService _service;
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
