import '../models/person.dart';
import '../models/participation_period.dart';
import '../models/year_month.dart';

abstract interface class ParticipationService {
  Stream<List<ParticipationPeriod>> watchPeriods(
    String groupId,
    String personId,
  );
  Future<void> change(
    String groupId,
    String actorUid,
    Person person,
    ParticipationPeriod? previous,
    YearMonth month,
    bool starting,
  );
}
