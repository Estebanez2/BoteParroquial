import 'dart:convert';
import '../core/errors/app_failure.dart';
import '../models/audit_history.dart';
import '../services/audit_history_service.dart';

final class AuditHistoryRepository {
  const AuditHistoryRepository(this._service);
  final AuditHistoryService _service;
  static const invalid = AppFailure(
    FailureCode.invalidData,
    'Los cambios administrativos no forman una página válida de este grupo. Actualiza el historial.',
  );

  static int compare(AuditCursor a, AuditCursor b) {
    final seconds = b.seconds.compareTo(a.seconds);
    if (seconds != 0) return seconds;
    final nanos = b.nanoseconds.compareTo(a.nanoseconds);
    if (nanos != 0) return nanos;
    final left = utf8.encode(b.eventId), right = utf8.encode(a.eventId);
    for (var index = 0; index < left.length && index < right.length; index++) {
      final order = left[index].compareTo(right[index]);
      if (order != 0) return order;
    }
    return left.length.compareTo(right.length);
  }

  static void _position(String groupId, AuditCursor cursor) {
    if (cursor.groupId != groupId ||
        cursor.eventId.isEmpty ||
        cursor.eventId.contains('/') ||
        cursor.nanoseconds < 0 ||
        cursor.nanoseconds >= 1000000000 ||
        cursor.seconds < -62135596800 ||
        cursor.seconds > 253402300799) {
      throw invalid;
    }
  }

  AuditPage _validate(String groupId, AuditPage page, [AuditCursor? after]) {
    if (groupId.isEmpty || page.groupId != groupId || page.events.length > 50) {
      throw invalid;
    }
    final seen = <String>{};
    AuditCursor? last = after;
    for (final event in page.events) {
      _position(groupId, event.position);
      if (!seen.add(event.id) ||
          (last != null && compare(last, event.position) >= 0) ||
          event.action.isEmpty ||
          event.actorUid.isEmpty ||
          event.entityId.isEmpty) {
        throw invalid;
      }
      last = event.position;
    }
    final next = page.nextCursor;
    if (next != null) {
      _position(groupId, next);
      if (page.events.isEmpty ||
          compare(next, page.events.last.position) != 0) {
        throw invalid;
      }
    }
    return page;
  }

  Stream<AuditPage> watchHead(String groupId) =>
      _service.watchHead(groupId).map((page) => _validate(groupId, page));
  Future<AuditPage> fetchOlder(String groupId, AuditCursor cursor) async {
    _position(groupId, cursor);
    final page = await _service.fetchOlder(groupId, cursor);
    if (!page.serverConfirmed) {
      throw const AppFailure(
        FailureCode.network,
        'No se pudo confirmar la página del historial.',
      );
    }
    return _validate(groupId, page, cursor);
  }

  List<GroupAuditEvent> append(
    String groupId,
    Iterable<GroupAuditEvent> current,
    AuditPage page,
  ) {
    final rows = current.toList();
    _validate(groupId, page, rows.isEmpty ? null : rows.last.position);
    if (rows.any((event) => event.groupId != groupId)) throw invalid;
    final ids = rows.map((event) => event.id).toSet();
    if (ids.length != rows.length ||
        page.events.any((event) => !ids.add(event.id))) {
      throw invalid;
    }
    return List.unmodifiable([...rows, ...page.events]);
  }

  static String _normalize(String value) {
    var text = value.toLowerCase();
    const accents = 'áéíóúüñ', plain = 'aeiouun';
    for (var index = 0; index < accents.length; index++) {
      text = text.replaceAll(accents[index], plain[index]);
    }
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<GroupAuditEvent> filter(
    String groupId,
    Iterable<GroupAuditEvent> events,
    AuditFilter filter, {
    Map<String, String> actors = const {},
    Map<String, String> actionLabels = const {},
  }) {
    final words = _normalize(
      filter.query,
    ).split(' ').where((word) => word.isNotEmpty);
    final result = <GroupAuditEvent>[];
    for (final event in events) {
      if (event.groupId != groupId) throw invalid;
      if (filter.entityType != null && event.entityType != filter.entityType) {
        continue;
      }
      if (filter.actorUid != null && event.actorUid != filter.actorUid) {
        continue;
      }
      final searchable = _normalize(
        [
          event.action,
          actionLabels[event.action] ?? '',
          event.actorUid,
          actors[event.actorUid] ?? '',
          event.entityType,
          event.entityId,
          ...?event.before?.values,
          ...event.after.values,
        ].join(' '),
      );
      if (words.every(searchable.contains)) result.add(event);
    }
    return List.unmodifiable(result);
  }
}
