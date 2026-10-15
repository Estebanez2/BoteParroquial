import '../services/group_clock_service.dart';

class GroupCalendarRepository {
  const GroupCalendarRepository(this._clock);
  final GroupClockService _clock;
  DateTime today(String timeZone) => _clock.today(timeZone);
}
