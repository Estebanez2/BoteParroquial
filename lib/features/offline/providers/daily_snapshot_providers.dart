import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../models/daily_snapshot.dart';
import '../../../repositories/daily_snapshot_repository.dart';
import '../../../repositories/snapshot_data_repository.dart';
import '../../../services/file_snapshot_storage.dart';
import '../../../services/firestore_snapshot_service.dart';
import '../../../services/group_clock_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../groups/providers/group_providers.dart';

final dailySnapshotRepositoryProvider = Provider((ref) {
  final auth = ref.watch(firebaseAuthProvider),
      db = ref.watch(firestoreProvider);
  final transport = SnapshotRestTransport(
    db.app.options.projectId,
    () => auth.currentUser?.getIdToken() ?? Future.value(null),
  );
  return DailySnapshotRepository(
    FileSnapshotStorage(),
    FirestoreSnapshotService(
      request: transport.call,
      currentUid: () => auth.currentUser?.uid,
    ),
    () => auth.currentUser?.uid,
  );
});

class DailyCopyState {
  const DailyCopyState({
    this.entries = const [],
    this.busy = false,
    this.error,
    this.revision = 0,
  });
  final List<SnapshotCatalogEntry> entries;
  final bool busy;
  final Object? error;
  final int revision;
}

final dailyCopyControllerProvider =
    NotifierProvider<DailyCopyController, DailyCopyState>(
      DailyCopyController.new,
    );

class DailyCopyController extends Notifier<DailyCopyState> {
  String? _uid;
  bool _foreground = true;
  Timer? _retry;
  int _generation = 0, _failures = 0;
  bool _refreshAgain = false;
  @override
  DailyCopyState build() {
    ref.onDispose(() => _retry?.cancel());
    ref.listen(authStateProvider, (_, next) {
      scheduleMicrotask(() {
        if (!ref.mounted) return;
        if (next.isLoading) return;
        final nextUid = next.asData?.value?.uid;
        if (_uid == nextUid) return;
        final old = _uid;
        _uid = nextUid;
        _generation++;
        _failures = 0;
        _retry?.cancel();
        state = const DailyCopyState();
        if (old != null) {
          unawaited(
            ref
                .read(dailySnapshotRepositoryProvider)
                .clear(old)
                .catchError((Object _) {}),
          );
        }
        if (nextUid != null) unawaited(refresh());
      });
    }, fireImmediately: true);
    // Membership metadata is only a trigger, not proof of current authorization.
    ref.listen(membershipsProvider, (_, next) {
      if (!next.isLoading && !next.hasError && _uid != null) {
        unawaited(refresh());
      }
    });
    return const DailyCopyState();
  }

  void foreground(bool active) {
    _foreground = active;
    if (active) {
      _failures = 0;
      unawaited(refresh());
    } else {
      _retry?.cancel();
    }
  }

  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null || !_foreground) return;
    if (state.busy) {
      _refreshAgain = true;
      return;
    }
    _retry?.cancel();
    final generation = _generation,
        repo = ref.read(dailySnapshotRepositoryProvider);
    bool current() => ref.mounted && generation == _generation && _uid == uid;
    repo.onAccessChanged = () {
      if (current()) {
        state = DailyCopyState(
          entries: state.entries,
          busy: state.busy,
          revision: repo.revision,
        );
      }
    };
    state = DailyCopyState(
      entries: state.entries,
      busy: true,
      revision: state.revision,
    );
    try {
      final local = await repo.storage.list(uid);
      if (!current()) return;
      state = DailyCopyState(
        entries: local,
        busy: true,
        revision: state.revision,
      );
      final day = TimeZoneGroupClockService()
          .today('Europe/Madrid')
          .toIso8601String()
          .substring(0, 10);
      await repo.refresh(uid, day);
      if (!current()) return;
      final entries = await repo.storage.list(uid);
      if (!current()) return;
      state = DailyCopyState(entries: entries, revision: repo.revision);
      _failures = 0;
      _retry?.cancel();
    } catch (e) {
      if (!current()) return;
      var entries = state.entries;
      try {
        entries = await repo.storage.list(uid);
      } catch (_) {
        /* Keep last catalog if local storage fails. */
      }
      if (!current()) return;
      state = DailyCopyState(
        entries: entries,
        error: e,
        revision: repo.revision,
      );
      // Foreground retry only; no work while the application is closed.
      if (_foreground && _failures++ < 4) {
        _retry?.cancel();
        _retry = Timer(
          Duration(seconds: 30 * _failures),
          () => unawaited(refresh()),
        );
      }
    } finally {
      if (current() && _refreshAgain) {
        _refreshAgain = false;
        unawaited(refresh());
      }
    }
  }

  Future<DailySnapshot> load(String day) async {
    final uid = _uid;
    if (uid == null) throw snapshotReadOnlyFailure;
    final copy = await ref
        .read(dailySnapshotRepositoryProvider)
        .storage
        .load(uid, day);
    if (_uid != uid) throw snapshotReadOnlyFailure;
    SnapshotDataRepository(copy);
    return copy;
  }

  Future<void> clear() async {
    final uid = _uid;
    if (uid == null) return;
    _generation++;
    _retry?.cancel();
    try {
      await ref.read(dailySnapshotRepositoryProvider).clear(uid);
      if (ref.mounted && _uid == uid) state = const DailyCopyState();
    } catch (_) {
      if (ref.mounted) {
        state = DailyCopyState(
          entries: state.entries,
          error: const AppFailure(
            FailureCode.unknown,
            'No se pudieron eliminar las copias locales.',
          ),
        );
      }
    }
  }
}
