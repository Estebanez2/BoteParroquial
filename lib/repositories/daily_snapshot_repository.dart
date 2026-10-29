import '../services/daily_snapshot_service.dart';
import '../models/daily_snapshot.dart';
import 'snapshot_data_repository.dart';

class DailySnapshotRepository {
  DailySnapshotRepository(this.storage, this.remote, this.currentUid);
  final SnapshotStorage storage;
  final SnapshotRemoteSource remote;
  final String? Function() currentUid;
  final _epochs = <String, int>{};
  final _running = <String, Future<void>>{};
  Map<String, String>? lastConfirmedAccess;
  int revision = 0;
  void Function()? onAccessChanged;
  Future<void> refresh(String uid, String day) {
    final running = _running[uid];
    if (running != null) return running;
    late final Future<void> task;
    task = _refresh(uid, day).whenComplete(() {
      if (identical(_running[uid], task)) _running.remove(uid);
    });
    _running[uid] = task;
    return task;
  }

  Future<void> _refresh(String uid, String day) async {
    final epoch = _epochs[uid] ?? 0;
    bool current() => currentUid() == uid && (_epochs[uid] ?? 0) == epoch;
    final access = await remote.access(uid);
    if (!current()) return;
    lastConfirmedAccess = Map.unmodifiable(access);
    revision++;
    onAccessChanged?.call();
    final effectiveDay = remote is SnapshotServerClock
        ? (remote as SnapshotServerClock).currentDay ?? day
        : day;
    try {
      await storage.restrict(uid, access);
    } catch (_) {
      await storage.clear(uid);
      rethrow;
    }
    if (!current()) return;
    // A first login may precede joining a group. Do not consume today's copy
    // with an empty scope; the membership change can then capture the real data.
    if (access.isEmpty) return;
    if ((await storage.list(uid)).any((e) => e.day == effectiveDay)) return;
    final copy = await remote.capture(uid, effectiveDay);
    if (!current()) return;
    if (copy.uid != uid || copy.day != effectiveDay) {
      throw DailySnapshot.invalid;
    }
    SnapshotDataRepository(copy);
    await storage.save(copy);
  }

  Future<void> clear(String uid) async {
    _epochs[uid] = (_epochs[uid] ?? 0) + 1;
    _running.remove(uid);
    lastConfirmedAccess = null;
    revision++;
    onAccessChanged?.call();
    await storage.clear(uid);
  }
}
