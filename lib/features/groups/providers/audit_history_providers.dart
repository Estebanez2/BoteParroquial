import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/audit_labels.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../models/audit_history.dart';
import '../../../repositories/audit_history_repository.dart';
import '../../../services/firestore_audit_history_service.dart';
import '../../auth/providers/auth_providers.dart';
import 'group_management_providers.dart';
import 'group_providers.dart';

final auditHistoryRepositoryProvider = Provider(
  (ref) => AuditHistoryRepository(
    FirestoreAuditHistoryService(ref.watch(firestoreProvider)),
  ),
);
final auditHistoryProvider = NotifierProvider.autoDispose
    .family<AuditHistoryController, AuditHistoryState, String>(
      AuditHistoryController.new,
    );

class AuditHistoryController extends Notifier<AuditHistoryState> {
  AuditHistoryController(this.groupId);
  final String groupId;
  int _generation = 0;
  String _headSignature = '';
  StreamSubscription<AuditPage>? _subscription;
  bool _current(int generation, String? uid) =>
      ref.mounted &&
      generation == _generation &&
      uid != null &&
      ref.read(authStateProvider).asData?.value?.uid == uid &&
      ref.read(canEditGroupProvider(groupId)) &&
      ref.read(groupProvider(groupId)).asData?.value != null &&
      generation == _generation;
  @override
  AuditHistoryState build() {
    final generation = ++_generation;
    final uid = ref.watch(
      authStateProvider.select((state) => state.asData?.value?.uid),
    );
    final allowed = ref.watch(canEditGroupProvider(groupId));
    final available = ref.watch(
      groupProvider(groupId).select((state) => state.asData?.value != null),
    );
    _headSignature = '';
    if (uid == null || !allowed || !available) return AuditHistoryState();
    final repository = ref.watch(auditHistoryRepositoryProvider);
    final subscription = repository
        .watchHead(groupId)
        .listen(
          (page) {
            if (!_current(generation, uid)) return;
            final signature = page.events
                .map((event) => event.id)
                .join('\u0000');
            if (!state.hasOlderPages) {
              _headSignature = signature;
              state = AuditHistoryState(
                events: page.events,
                nextCursor: page.nextCursor,
                serverConfirmed: page.serverConfirmed,
              );
            } else {
              // Once paging starts, freeze its boundary. Do not merge a moving head:
              // a burst larger than one page could silently leave a hole in history.
              state = state.copyWith(
                serverConfirmed: page.serverConfirmed,
                hasNewChanges:
                    state.hasNewChanges ||
                    (page.serverConfirmed && signature != _headSignature),
              );
            }
          },
          onError: (Object error, StackTrace _) {
            if (!_current(generation, uid)) return;
            if (error is AppFailure && error.code == FailureCode.network) {
              state = state.copyWith(
                serverConfirmed: false,
                loading: false,
                error: error,
              );
            } else {
              _generation++;
              state = AuditHistoryState(error: error);
              unawaited(_subscription?.cancel());
            }
          },
        );
    _subscription = subscription;
    ref.onDispose(() {
      if (_generation == generation) _generation++;
      unawaited(subscription.cancel());
    });
    return AuditHistoryState(loading: true);
  }

  void refresh() => ref.invalidateSelf();
  Future<void> loadMore() async {
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (!_current(_generation, uid)) return;
    final cursor = state.nextCursor;
    if (!state.canLoadMore || cursor == null) return;
    final generation = _generation;
    final repository = ref.read(auditHistoryRepositoryProvider);
    state = state.copyWith(
      loadingMore: true,
      hasOlderPages: true,
      clearError: true,
    );
    try {
      final page = await repository.fetchOlder(groupId, cursor);
      if (!_current(generation, uid)) return;
      state = state.copyWith(
        events: repository.append(groupId, state.events, page),
        cursor: page.nextCursor,
        replaceCursor: true,
        loadingMore: false,
        clearError: true,
      );
    } catch (error) {
      if (!_current(generation, uid)) return;
      if (error is AppFailure &&
          (error.code == FailureCode.permissionDenied ||
              error.code == FailureCode.invalidData)) {
        _generation++;
        state = AuditHistoryState(error: error);
        unawaited(_subscription?.cancel());
      } else {
        state = state.copyWith(loadingMore: false, error: error);
      }
    }
  }
}

final auditFilterProvider = NotifierProvider.autoDispose
    .family<AuditFilterController, AuditFilter, String>(
      AuditFilterController.new,
    );

class AuditFilterController extends Notifier<AuditFilter> {
  AuditFilterController(this.groupId);
  final String groupId;
  @override
  AuditFilter build() {
    ref.watch(authStateProvider.select((state) => state.asData?.value?.uid));
    ref.watch(canEditGroupProvider(groupId));
    return const AuditFilter();
  }

  void search(String query) => state = AuditFilter(
    query: query,
    entityType: state.entityType,
    actorUid: state.actorUid,
  );
  void entity(String? type) => state = AuditFilter(
    query: state.query,
    entityType: type,
    actorUid: state.actorUid,
  );
  void actor(String? uid) => state = AuditFilter(
    query: state.query,
    entityType: state.entityType,
    actorUid: uid,
  );
  void reset() => state = const AuditFilter();
}

final auditActorsProvider = Provider.autoDispose
    .family<Map<String, String>, String>((ref, id) {
      final members = ref.watch(groupMembersProvider(id)).asData?.value ?? [];
      final actors = {
        for (final member in members) member.uid: member.displayName,
      };
      final selected = ref.watch(auditFilterProvider(id)).actorUid;
      if (selected != null) {
        actors.putIfAbsent(selected, () => 'Usuario no disponible · $selected');
      }
      for (final event in ref.watch(auditHistoryProvider(id)).events) {
        actors.putIfAbsent(
          event.actorUid,
          () => event.actorUid == 'system:backfill-person-links'
              ? 'Preparación técnica de vínculos'
              : 'Usuario no disponible · ${event.actorUid}',
        );
      }
      return Map.unmodifiable(actors);
    });
final filteredAuditProvider = Provider.autoDispose
    .family<List<GroupAuditEvent>, String>((ref, id) {
      if (!ref.watch(canEditGroupProvider(id))) return const [];
      final history = ref.watch(auditHistoryProvider(id));
      return ref
          .watch(auditHistoryRepositoryProvider)
          .filter(
            id,
            history.events,
            ref.watch(auditFilterProvider(id)),
            actors: ref.watch(auditActorsProvider(id)),
            actionLabels: auditActionLabels,
          );
    });
