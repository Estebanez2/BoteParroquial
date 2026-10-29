/// Opaque position in a group's immutable administrative history. Preserve
/// nanoseconds: DateTime alone can skip rows sharing a microsecond boundary.
final class AuditCursor {
  const AuditCursor({
    required this.groupId,
    required this.eventId,
    required this.seconds,
    required this.nanoseconds,
  });
  final String groupId, eventId;
  final int seconds, nanoseconds;
  DateTime get date => DateTime.fromMicrosecondsSinceEpoch(
    seconds * 1000000 + nanoseconds ~/ 1000,
    isUtc: true,
  );
}

final class GroupAuditEvent {
  GroupAuditEvent({
    required this.position,
    required this.action,
    required this.actorUid,
    required this.entityId,
    required Map<String, Object?>? before,
    required Map<String, Object?> after,
    this.entityType = 'group',
  }) : before = before == null ? null : Map.unmodifiable(before),
       after = Map.unmodifiable(after);
  final AuditCursor position;
  String get id => position.eventId;
  String get groupId => position.groupId;
  DateTime get createdAt => position.date;
  final String action, actorUid, entityType, entityId;
  final Map<String, Object?>? before;
  final Map<String, Object?> after;
}

final class AuditPage {
  AuditPage({
    required this.groupId,
    required Iterable<GroupAuditEvent> events,
    required this.nextCursor,
    required this.serverConfirmed,
  }) : events = List.unmodifiable(events);
  final String groupId;
  final List<GroupAuditEvent> events;
  final AuditCursor? nextCursor;
  final bool serverConfirmed;
}

final class AuditFilter {
  const AuditFilter({this.query = '', this.entityType, this.actorUid});
  final String query;
  final String? entityType, actorUid;
}

final class AuditHistoryState {
  AuditHistoryState({
    Iterable<GroupAuditEvent> events = const [],
    this.nextCursor,
    this.serverConfirmed = false,
    this.loading = false,
    this.loadingMore = false,
    this.hasOlderPages = false,
    this.hasNewChanges = false,
    this.error,
  }) : events = List.unmodifiable(events);
  final List<GroupAuditEvent> events;
  final AuditCursor? nextCursor;
  final bool serverConfirmed,
      loading,
      loadingMore,
      hasOlderPages,
      hasNewChanges;
  final Object? error;
  bool get canLoadMore =>
      serverConfirmed && nextCursor != null && !loading && !loadingMore;
  AuditHistoryState copyWith({
    Iterable<GroupAuditEvent>? events,
    AuditCursor? cursor,
    bool replaceCursor = false,
    bool? serverConfirmed,
    bool? loading,
    bool? loadingMore,
    bool? hasOlderPages,
    bool? hasNewChanges,
    Object? error,
    bool clearError = false,
  }) => AuditHistoryState(
    events: events ?? this.events,
    nextCursor: replaceCursor ? cursor : nextCursor,
    serverConfirmed: serverConfirmed ?? this.serverConfirmed,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    hasOlderPages: hasOlderPages ?? this.hasOlderPages,
    hasNewChanges: hasNewChanges ?? this.hasNewChanges,
    error: clearError ? null : error ?? this.error,
  );
}
