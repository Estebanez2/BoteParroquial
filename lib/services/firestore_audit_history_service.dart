import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';
import '../models/audit_history.dart';
import 'audit_history_service.dart';
import 'firestore_audit_decoder.dart';

final class FirestoreAuditHistoryService implements AuditHistoryService {
  const FirestoreAuditHistoryService(this._db);
  final FirebaseFirestore _db;
  static const pageSize = 50;
  Query<Map<String, dynamic>> _query(String groupId) => _db
      .collection(FirestorePaths.auditEvents(groupId))
      .orderBy('createdAt', descending: true)
      .orderBy(FieldPath.documentId, descending: true);
  static AppFailure _failure(FirebaseException error) => switch (error.code) {
    'permission-denied' || 'unauthenticated' => const AppFailure(
      FailureCode.permissionDenied,
      'Ya no tienes permiso para consultar este historial.',
    ),
    'unavailable' || 'deadline-exceeded' => const AppFailure(
      FailureCode.network,
      'No se pudo consultar el historial en el servidor. Comprueba la conexión y reintenta.',
    ),
    _ => const AppFailure(
      FailureCode.unknown,
      'No se pudo cargar el historial administrativo.',
    ),
  };
  AuditPage _page(
    String groupId,
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final events = snapshot.docs
        .where((doc) => !doc.metadata.hasPendingWrites)
        .map(
          (doc) =>
              decodeAuditEvent(groupId, doc.id, doc.reference.path, doc.data()),
        )
        .toList();
    final selected = events.take(pageSize).toList();
    return AuditPage(
      groupId: groupId,
      events: selected,
      nextCursor: events.length > pageSize ? selected.last.position : null,
      serverConfirmed:
          !snapshot.metadata.isFromCache && !snapshot.metadata.hasPendingWrites,
    );
  }

  @override
  Stream<AuditPage> watchHead(String groupId) async* {
    try {
      yield* _query(groupId)
          .limit(pageSize + 1)
          .snapshots(includeMetadataChanges: true)
          .map((data) => _page(groupId, data));
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<AuditPage> fetchOlder(String groupId, AuditCursor cursor) async {
    if (cursor.groupId != groupId ||
        cursor.nanoseconds < 0 ||
        cursor.nanoseconds >= 1000000000) {
      throw const AppFailure(
        FailureCode.invalidData,
        'La posición del historial no pertenece a esta consulta.',
      );
    }
    try {
      final snapshot = await _query(groupId)
          .startAfter([
            Timestamp(cursor.seconds, cursor.nanoseconds),
            cursor.eventId,
          ])
          .limit(pageSize + 1)
          .get(const GetOptions(source: Source.server));
      final page = _page(groupId, snapshot);
      if (!page.serverConfirmed) {
        throw const AppFailure(
          FailureCode.network,
          'Espera a que se confirme la conexión para consultar cambios antiguos.',
        );
      }
      return page;
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }
}
