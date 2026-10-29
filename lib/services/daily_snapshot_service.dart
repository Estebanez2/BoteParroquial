import '../models/daily_snapshot.dart';

abstract interface class SnapshotStorage {
  Future<List<SnapshotCatalogEntry>> list(String uid);
  Future<DailySnapshot> load(String uid, String day);
  Future<void> save(DailySnapshot snapshot);
  Future<void> clear(String uid);

  /// Drop entire group-containing copies on revocation or reduced privileges.
  Future<void> restrict(String uid, Map<String, String> currentAccess);
}

abstract interface class SnapshotRemoteSource {
  Future<Map<String, String>> access(String uid);
  Future<DailySnapshot> capture(String uid, String day);
}

abstract interface class SnapshotServerClock {
  String? get currentDay;
}
