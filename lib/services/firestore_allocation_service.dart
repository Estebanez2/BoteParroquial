import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';
import '../models/quota_allocation.dart';
import '../models/year_month.dart';
import 'allocation_service.dart';

final class FirestoreAllocationService implements AllocationService {
  const FirestoreAllocationService(this._store);
  final FirebaseFirestore _store;
  static const _conflict = AppFailure(
    FailureCode.invalidData,
    'El ingreso o su reparto ha cambiado. Actualiza la pantalla y revisa el resultado antes de repetir.',
  );
  static const _invalid = AppFailure(
    FailureCode.invalidData,
    'Una asignación tiene un formato no válido.',
  );
  static AppFailure _failure(FirebaseException error) => switch (error.code) {
    'permission-denied' || 'unauthenticated' => const AppFailure(
      FailureCode.permissionDenied,
      'No tienes permiso para cambiar estas asignaciones.',
    ),
    'unavailable' || 'deadline-exceeded' || 'aborted' => const AppFailure(
      FailureCode.network,
      'No se pudo confirmar el reparto. Comprueba la conexión y revisa el mes antes de reintentar.',
    ),
    _ => const AppFailure(
      FailureCode.unknown,
      'No se pudo confirmar el reparto. Actualiza la pantalla para comprobarlo.',
    ),
  };
  @override
  String newOperationId(String groupId) =>
      _store.collection(FirestorePaths.auditEvents(groupId)).doc().id;

  static QuotaAllocation parseAllocation(
    String groupId,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    if (d['movementId'] is! String ||
        d['personId'] is! String ||
        d['month'] is! int ||
        d['month'] < 24000 ||
        d['month'] > 25211 ||
        d['amountCents'] is! int ||
        d['amountCents'] < 0 ||
        d['amountCents'] > 99999999999999 ||
        d['revision'] is! int ||
        d['revision'] < 1 ||
        d['participationPeriodId'] is! String ||
        d['updatedAt'] is! Timestamp ||
        doc.id != '${d['movementId']}_${d['month']}') {
      throw _invalid;
    }
    final month = d['month'] as int;
    return QuotaAllocation(
      id: doc.id,
      groupId: groupId,
      movementId: d['movementId'],
      personId: d['personId'],
      month: YearMonth(month ~/ 12, month % 12 + 1),
      amountCents: d['amountCents'],
      revision: d['revision'],
      participationPeriodId: d['participationPeriodId'],
    );
  }

  @override
  Stream<List<QuotaAllocation>> watchAllocations(
    String groupId,
    String personId,
  ) async* {
    try {
      yield* _store
          .collection(FirestorePaths.allocations(groupId))
          .where('personId', isEqualTo: personId)
          .snapshots(includeMetadataChanges: true)
          .map(
            (s) => List.unmodifiable(
              s.docs
                  .where((d) => !d.metadata.hasPendingWrites)
                  .map((d) => parseAllocation(groupId, d)),
            ),
          );
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  Map<String, Object?> _summary(Map<String, dynamic> data) => {
    'movementId': data['movementId'],
    'personId': data['personId'],
    'month': data['month'],
    'amountCents': data['amountCents'],
    'revision': data['revision'],
  };
  @override
  Future<void> change(
    String groupId,
    String actorUid,
    AllocationChange change,
  ) async {
    final source = change.movement;
    final id = '${source.id}_${change.month.ordinal}';
    final rowRef = _store.doc(FirestorePaths.allocation(groupId, id));
    final balanceRef = _store.doc(
      FirestorePaths.allocationBalance(groupId, source.id),
    );
    final auditRef = _store.doc(
      FirestorePaths.auditEvent(groupId, change.operationId),
    );
    try {
      await _store.runTransaction((tx) async {
        final audit = (await tx.get(auditRef)).data();
        final afterSummary = <String, Object?>{
          'movementId': source.id,
          'personId': source.input.personId,
          'month': change.month.ordinal,
          'amountCents': change.amountCents,
          'revision': (change.previous?.revision ?? 0) + 1,
        };
        if (audit != null) {
          final after = audit['after'];
          if (audit['action'] != 'allocation.changed' ||
              audit['actorUid'] != actorUid ||
              audit['entityId'] != id ||
              after is! Map ||
              after.length != afterSummary.length ||
              afterSummary.entries.any((e) => after[e.key] != e.value)) {
            throw _conflict;
          }
          return; // Same operation acknowledged, even if later edited by someone else.
        }
        final movement = (await tx.get(
          _store.doc(FirestorePaths.movement(groupId, source.id)),
        )).data();
        final before = (await tx.get(rowRef)).data();
        final balance = (await tx.get(balanceRef)).data();
        final period = (await tx.get(
          _store.doc(
            FirestorePaths.participationPeriod(
              groupId,
              change.participationPeriodId,
            ),
          ),
        )).data();
        if (movement?['status'] != 'active' ||
            movement?['type'] != 'income' ||
            movement?['personId'] != source.input.personId ||
            movement?['amountCents'] != source.input.amountCents ||
            movement?['updatedAt'] != Timestamp.fromDate(source.updatedAt) ||
            (before == null) != (change.previous == null) ||
            (before != null &&
                (before['revision'] != change.previous?.revision ||
                    before['amountCents'] != change.previous?.amountCents))) {
          throw _conflict;
        }
        if (change.amountCents > 0 &&
            (period?['personId'] != source.input.personId ||
                period?['firstMonth'] is! int ||
                period!['firstMonth'] > change.month.ordinal ||
                (period['lastMonthInclusive'] != null &&
                    period['lastMonthInclusive'] < change.month.ordinal))) {
          throw _conflict;
        }
        final allocated = balance?['allocatedCents'] ?? 0;
        final oldAmount = before?['amountCents'] ?? 0;
        if (allocated is! int ||
            oldAmount is! int ||
            (before != null && balance == null)) {
          throw _conflict;
        }
        final total = allocated - oldAmount + change.amountCents;
        final refunded = balance?['refundedCents'] as int? ?? 0;
        final returnedAssigned = balance?['refundedAssignedCents'] as int? ?? 0;
        final returnedMonth =
            (balance?['refundedMonths'] as Map?)?['${change.month.ordinal}']
                as int? ??
            0;
        if (total < 0 ||
            total + refunded - returnedAssigned > source.input.amountCents ||
            change.amountCents < returnedMonth) {
          throw _conflict;
        }
        final now = FieldValue.serverTimestamp();
        final data = <String, dynamic>{
          ...afterSummary,
          'participationPeriodId': change.participationPeriodId,
          'createdBy': before?['createdBy'] ?? actorUid,
          'createdAt': before?['createdAt'] ?? now,
          'updatedBy': actorUid,
          'updatedAt': now,
          'lastAuditEventId': change.operationId,
        };
        tx.set(rowRef, data);
        tx.set(balanceRef, {
          ...?balance,
          'allocatedCents': total,
          'revision': (balance?['revision'] as int? ?? 0) + 1,
          'lastAllocationId': id,
          'lastAuditEventId': change.operationId,
          'updatedAt': now,
          'updatedBy': actorUid,
        });
        tx.set(auditRef, {
          'action': 'allocation.changed',
          'entityType': 'allocation',
          'entityId': id,
          'actorUid': actorUid,
          'createdAt': now,
          'before': before == null ? null : _summary(before),
          'after': afterSummary,
        });
      });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }
}
