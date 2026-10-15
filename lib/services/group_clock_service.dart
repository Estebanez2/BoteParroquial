import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;
import '../core/errors/app_failure.dart';

abstract interface class GroupClockService {
  DateTime today(String timeZone);
}

class TimeZoneGroupClockService implements GroupClockService {
  TimeZoneGroupClockService({DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  static bool _initialized = false;
  @override
  DateTime today(String timeZone) {
    if (!_initialized) {
      data.initializeTimeZones();
      _initialized = true;
    }
    try {
      final date = tz.TZDateTime.from(_now().toUtc(), tz.getLocation(timeZone));
      return DateTime.utc(date.year, date.month, date.day);
    } catch (_) {
      throw const AppFailure(
        FailureCode.configuration,
        'La zona horaria del grupo no es válida. No se puede confirmar la fecha.',
      );
    }
  }
}
