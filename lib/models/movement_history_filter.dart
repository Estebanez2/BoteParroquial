import 'movement.dart';

/// Read-only criteria for a group's economic history, using effective dates.
class MovementHistoryFilter {
  const MovementHistoryFilter({
    this.query = '',
    this.type,
    this.status,
    this.personId,
    this.groupOnly = false,
    this.authorUid,
    this.fromDate,
    this.toDate,
  });

  final String query;
  final MovementType? type;
  final MovementStatus? status;
  final String? personId, authorUid;
  final bool groupOnly;
  final DateTime? fromDate, toDate;

  int get criteriaCount => [
    query.trim().isNotEmpty,
    type != null,
    status != null,
    personId != null || groupOnly,
    authorUid != null,
    fromDate != null || toDate != null,
  ].where((active) => active).length;

  MovementHistoryFilter copyWith({
    String? query,
    MovementType? type,
    bool clearType = false,
    MovementStatus? status,
    bool clearStatus = false,
    String? personId,
    bool clearPerson = false,
    bool? groupOnly,
    String? authorUid,
    bool clearAuthor = false,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearDates = false,
  }) => MovementHistoryFilter(
    query: query ?? this.query,
    type: clearType ? null : type ?? this.type,
    status: clearStatus ? null : status ?? this.status,
    personId: clearPerson ? null : personId ?? this.personId,
    groupOnly: groupOnly ?? this.groupOnly,
    authorUid: clearAuthor ? null : authorUid ?? this.authorUid,
    fromDate: clearDates ? null : fromDate ?? this.fromDate,
    toDate: clearDates ? null : toDate ?? this.toDate,
  );
}

class MovementHistoryOptions {
  MovementHistoryOptions({
    required Map<String, String> persons,
    required Map<String, String> authors,
  }) : persons = Map.unmodifiable(persons),
       authors = Map.unmodifiable(authors);

  final Map<String, String> persons, authors;
}
