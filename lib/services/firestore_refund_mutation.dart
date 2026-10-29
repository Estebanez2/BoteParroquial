import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';
import '../models/refund_plan.dart';

/// Reads first, then applies one atomic financial transition with its witnesses.
final class FirestoreRefundMutation {
  FirestoreRefundMutation._(
    this.operationId,
    this._store,
    this._groupId,
    this._actor,
    this._operation,
    this._balance,
  );
  final String operationId, _groupId, _actor;
  final FirebaseFirestore _store;
  final Map<String, Object?> _operation;
  final Map<String, dynamic> _balance;
  static const _conflict = AppFailure(
    FailureCode.invalidData,
    'El ingreso o sus cuotas han cambiado. Revisa la devolución antes de repetir; no se guardarán cambios parciales.',
  );

  static Future<FirestoreRefundMutation?> prepare(
    FirebaseFirestore store,
    Transaction tx, {
    required String groupId,
    required String actorUid,
    required String kind,
    required String? originalId,
    required String? targetId,
    required RefundPlan? before,
    required RefundPlan? after,
    required String? personId,
  }) async {
    if (before == null && after == null) return null;
    final sourceId = before?.incomeId ?? after!.incomeId;
    if (after != null && after.incomeId != sourceId) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Para cambiar el ingreso de origen, anula esta devolución y registra otra.',
      );
    }
    if (sourceId == originalId || sourceId == targetId) throw _conflict;
    final months = {
      ...?(before?.parts.map((p) => p.month)),
      ...?(after?.parts.map((p) => p.month)),
    }.toList()..sort();
    if (months.length > 4) {
      throw const AppFailure(
        FailureCode.invalidData,
        'La operación puede afectar hasta cuatro meses distintos, contando los del original. Para cambiar más, anula y registra otra devolución.',
      );
    }
    final income = (await tx.get(
      store.doc(FirestorePaths.movement(groupId, sourceId)),
    )).data();
    final balance =
        (await tx.get(
          store.doc(FirestorePaths.allocationBalance(groupId, sourceId)),
        )).data() ??
        <String, dynamic>{};
    if (income?['type'] != 'income' ||
        income?['status'] != 'active' ||
        income?['personId'] != personId ||
        income?['amountCents'] is! int) {
      throw _conflict;
    }
    final operationId = kind == 'cancel'
        ? 'refund-cancel-$originalId'
        : 'refund-$targetId';
    if ((await tx.get(
      store.doc(FirestorePaths.refundOperation(groupId, operationId)),
    )).exists) {
      throw _conflict;
    }
    final refundedMonths = Map<String, dynamic>.from(
      balance['refundedMonths'] as Map? ?? {},
    );
    final changes = <String>[];
    for (final month in months) {
      final id = '${sourceId}_${month.ordinal}';
      final data = (await tx.get(
        store.doc(FirestorePaths.allocation(groupId, id)),
      )).data();
      if (data == null ||
          data['movementId'] != sourceId ||
          data['personId'] != personId ||
          data['amountCents'] is! int ||
          data['revision'] is! int) {
        throw _conflict;
      }
      final key = '${month.ordinal}',
          held = refundedMonths['${month.ordinal}'] ?? 0;
      if (held is! int) throw _conflict;
      final next =
          held - (before?.atMonth(month) ?? 0) + (after?.atMonth(month) ?? 0);
      if (next < 0 || next > (data['amountCents'] as int)) throw _conflict;
      if (next == 0) {
        refundedMonths.remove(key);
      } else {
        refundedMonths[key] = next;
      }
      changes.add(key);
    }
    final assigned = balance['allocatedCents'] ?? 0,
        refunded = balance['refundedCents'] ?? 0;
    if (assigned is! int || refunded is! int) throw _conflict;
    final nextAssigned =
        (balance['refundedAssignedCents'] as int? ?? 0) -
        (before?.assignedCents ?? 0) +
        (after?.assignedCents ?? 0);
    final nextRefunded =
        refunded - (before?.amountCents ?? 0) + (after?.amountCents ?? 0);
    if (nextAssigned < 0 ||
        nextRefunded < 0 ||
        nextAssigned > nextRefunded ||
        nextAssigned > assigned ||
        assigned + nextRefunded - nextAssigned >
            (income!['amountCents'] as int)) {
      throw _conflict;
    }
    return FirestoreRefundMutation._(
      operationId,
      store,
      groupId,
      actorUid,
      {
        'kind': kind,
        'incomeId': sourceId,
        'originalMovementId': originalId,
        'targetMovementId': targetId,
        'previousAmountCents': before?.amountCents ?? 0,
        'amountCents': after?.amountCents ?? 0,
        'previousAssignedCents': before?.assignedCents ?? 0,
        'assignedCents': after?.assignedCents ?? 0,
        'changes': changes,
        'previousRefund': before?.toMap(),
        'refund': after?.toMap(),
      },
      {
        ...balance,
        'allocatedCents': assigned,
        'refundedCents': nextRefunded,
        'refundedAssignedCents': nextAssigned,
        'refundedMonths': refundedMonths,
      },
    );
  }

  void write(Transaction tx) {
    final now = FieldValue.serverTimestamp();
    tx.set(
      _store.doc(
        FirestorePaths.allocationBalance(
          _groupId,
          _operation['incomeId'] as String,
        ),
      ),
      {
        ..._balance,
        'lastAllocationId': _balance['lastAllocationId'],
        'revision': (_balance['revision'] as int? ?? 0) + 1,
        'lastAuditEventId': operationId,
        'lastRefundOperationId': operationId,
        'updatedAt': now,
        'updatedBy': _actor,
      },
    );
    tx.set(_store.doc(FirestorePaths.auditEvent(_groupId, operationId)), {
      ..._operation,
      'action': 'refund.${_operation['kind']}',
      'entityType': 'refund',
      'entityId': operationId,
      'actorUid': _actor,
      'createdAt': now,
      'before': {
        'incomeId': _operation['incomeId'],
        'movementId': _operation['originalMovementId'],
        'amountCents': _operation['previousAmountCents'],
      },
      'after': {
        'incomeId': _operation['incomeId'],
        'movementId': _operation['targetMovementId'],
        'amountCents': _operation['amountCents'],
      },
    });
  }
}
