import '../core/errors/app_failure.dart';

const snapshotReadOnlyFailure = AppFailure(
  FailureCode.permissionDenied,
  'Estás consultando una copia de solo lectura. Vuelve a los datos actuales para realizar cambios.',
);

class SnapshotDocument {
  SnapshotDocument(this.path, Map<String, Object?> fields)
    : fields = Map.unmodifiable(fields);
  final String path;

  /// Original Firestore REST values: int64 and timestamp precision survive JSON.
  final Map<String, Object?> fields;
  String get id => path.split('/').last;
  Map<String, Object?> toJson() => {'path': path, 'fields': fields};
}

class DailySnapshot {
  DailySnapshot({
    required this.uid,
    required this.day,
    required this.readTime,
    required this.savedAt,
    required Iterable<SnapshotDocument> documents,
  }) : documents = List.unmodifiable(documents) {
    if (uid.isEmpty ||
        !RegExp(r'^\d{4}-\d\d-\d\d$').hasMatch(day) ||
        DateTime.tryParse(readTime) == null ||
        this.documents.length > 100000) {
      throw invalid;
    }
    final seen = <String>{};
    for (final doc in this.documents) {
      final parts = doc.path.split('/');
      if (parts.length.isOdd ||
          parts.any((p) => p.isEmpty || p == '.' || p == '..') ||
          !seen.add(doc.path) ||
          !(parts.first == 'groups' ||
              (parts.first == 'users' && parts[1] == uid)) ||
          parts.any(
            (p) => [
              'pushDevices',
              'notificationDeliveries',
              'notificationWorker',
              'notificationDeviceStates',
              'accountLifecycle',
              'groupDeletionTasks',
            ].contains(p),
          )) {
        throw invalid;
      }
    }
  }
  static const invalid = AppFailure(
    FailureCode.invalidData,
    'La copia no está completa o no tiene un formato válido. Conserva otra copia y vuelve a intentarlo con conexión.',
  );
  final String uid, day, readTime;
  final DateTime savedAt;
  final List<SnapshotDocument> documents;
  DateTime get asOf => DateTime.parse(readTime).toUtc();
  List<String> get groupIds => documents
      .where(
        (d) => d.path.startsWith('groups/') && d.path.split('/').length == 2,
      )
      .map((d) => d.id)
      .toList(growable: false);
  Map<String, Object?> toJson() => {
    'version': 1,
    'uid': uid,
    'day': day,
    'readTime': readTime,
    'savedAt': savedAt.toUtc().toIso8601String(),
    'documents': documents.map((d) => d.toJson()).toList(),
  };
  factory DailySnapshot.fromJson(
    Map<String, Object?> data,
    String expectedUid,
  ) {
    if (data['version'] != 1 ||
        data['uid'] != expectedUid ||
        data['documents'] is! List) {
      throw invalid;
    }
    try {
      return DailySnapshot(
        uid: expectedUid,
        day: data['day'] as String,
        readTime: data['readTime'] as String,
        savedAt: DateTime.parse(data['savedAt'] as String),
        documents: (data['documents'] as List).map((raw) {
          final d = raw as Map;
          return SnapshotDocument(
            d['path'] as String,
            Map<String, Object?>.from(d['fields'] as Map),
          );
        }),
      );
    } catch (_) {
      throw invalid;
    }
  }
}

class SnapshotCatalogEntry {
  const SnapshotCatalogEntry(this.day, this.asOf, this.groups, this.documents);
  final String day;
  final DateTime asOf;
  final int groups, documents;
}
