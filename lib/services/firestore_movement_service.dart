import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';
import '../models/movement.dart';
import '../models/initial_quota_assignment.dart';
import 'initial_quota_movement_service.dart';
import 'firestore_initial_quota_mutation.dart';
import '../models/refund_plan.dart';
import 'movement_service.dart';
import 'firestore_refund_mutation.dart';
import 'firestore_movement_trace.dart';
import 'movement_dashboard_source.dart';
import 'firestore_cash_aggregate_service.dart';
import 'file_cash_cache.dart';
import '../models/movement_cash_totals.dart';
import '../models/monthly_balance.dart';
import '../models/year_month.dart';
import 'movement_trend_source.dart';

class FirestoreMovementService
    implements
        MovementService,
        MovementDashboardSource,
        InitialQuotaMovementService,
        MovementTrendSource {
  const FirestoreMovementService(this._firestore);
  final FirebaseFirestore _firestore;
  @override
  Future<List<MonthlyBalance>> loadBalanceTrend(
    String groupId,
    String uid,
    YearMonth currentMonth,
  ) async {
    final service = FirestoreCashAggregateService(_firestore);
    Future<MovementCashTotals> at(YearMonth month, String? readTime) =>
        service.load(
          groupId,
          uid,
          month.firstDayUtc,
          beforeExclusive: month.addMonths(1).firstDayUtc,
          atReadTime: readTime,
          totalsOnly: true,
        );
    final firstMonth = currentMonth.addMonths(-5);
    final first = await at(firstMonth, null);
    final time = first.confirmedAt.toUtc().toIso8601String();
    final rest = await Future.wait(
      List.generate(5, (i) => at(firstMonth.addMonths(i + 1), time)),
    );
    return List.unmodifiable([
      MonthlyBalance(firstMonth, first.balanceCents),
      for (var i = 0; i < rest.length; i++)
        MonthlyBalance(firstMonth.addMonths(i + 1), rest[i].balanceCents),
    ]);
  }

  static const _conflict = AppFailure(
    FailureCode.invalidData,
    'El movimiento ya ha cambiado o este envío ya existe con otros datos. Revisa el historial.',
  );
  static const _invalid = AppFailure(
    FailureCode.invalidData,
    'Un movimiento tiene un formato no válido.',
  );
  static AppFailure _failure(FirebaseException error) => switch (error.code) {
    'resource-exhausted' => firestoreQuotaFailure,
    'permission-denied' || 'unauthenticated' => const AppFailure(
      FailureCode.permissionDenied,
      'No tienes permiso para realizar esta operación en el grupo.',
    ),
    'unavailable' || 'deadline-exceeded' || 'aborted' => const AppFailure(
      FailureCode.network,
      'No se pudo confirmar la operación. Comprueba la conexión y reintenta este mismo envío.',
    ),
    _ => const AppFailure(
      FailureCode.unknown,
      'No se pudo confirmar el movimiento. Revisa el historial antes de iniciar otro envío.',
    ),
  };
  CollectionReference<Map<String, dynamic>> _collection(String groupId) =>
      _firestore.collection(FirestorePaths.movements(groupId));
  @override
  String newId(String groupId) => _collection(groupId).doc().id;
  static DateTime _date(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value is! Timestamp) throw _invalid;
    return value.toDate().toUtc();
  }

  static String? _optional(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value != null && value is! String) throw _invalid;
    return value as String?;
  }

  static Movement _parse(
    String groupId,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if ((data['status'] == 'cancelled' &&
            (data['cancelledBy'] is! String ||
                data['cancellationReason'] is! String ||
                data['cancelledAt'] is! Timestamp)) ||
        (data['status'] == 'corrected' &&
            (data['correctedBy'] is! String ||
                data['correctionReason'] is! String ||
                data['correctedAt'] is! Timestamp ||
                data['correctedByMovementId'] is! String))) {
      throw _invalid;
    }
    if (data['amountCents'] is! int ||
        data['description'] is! String ||
        data['createdBy'] is! String) {
      throw _invalid;
    }
    return Movement(
      id: doc.id,
      groupId: groupId,
      input: MovementInput(
        type: switch (data['type']) {
          'income' => MovementType.income,
          'withdrawal' => MovementType.withdrawal,
          _ => throw _invalid,
        },
        amountCents: data['amountCents'] as int,
        description: data['description'] as String,
        personId: _optional(data, 'personId'),
        occurredAt: _date(data, 'occurredAt'),
        refund: RefundPlan.fromMap(data['refund']),
      ),
      status: switch (data['status']) {
        'active' => MovementStatus.active,
        'cancelled' => MovementStatus.cancelled,
        'corrected' => MovementStatus.corrected,
        _ => throw _invalid,
      },
      createdBy: data['createdBy'] as String,
      createdAt: _date(data, 'createdAt'),
      updatedAt: _date(data, 'updatedAt'),
      cancelledBy: _optional(data, 'cancelledBy'),
      cancelledAt: data['cancelledAt'] == null
          ? null
          : _date(data, 'cancelledAt'),
      cancellationReason: _optional(data, 'cancellationReason'),
      correctedBy: _optional(data, 'correctedBy'),
      correctedAt: data['correctedAt'] == null
          ? null
          : _date(data, 'correctedAt'),
      correctionReason: _optional(data, 'correctionReason'),
      correctedByMovementId: _optional(data, 'correctedByMovementId'),
      correctionOfMovementId: _optional(data, 'correctionOfMovementId'),
    );
  }

  List<Movement> _list(
    String groupId,
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final list = snapshot.docs
        .where((doc) => !doc.metadata.hasPendingWrites)
        .map((doc) => _parse(groupId, doc))
        .toList();
    list.sort((a, b) {
      final date = b.input.occurredAt.compareTo(a.input.occurredAt);
      if (date != 0) return date;
      final created = b.createdAt.compareTo(a.createdAt);
      return created != 0 ? created : a.id.compareTo(b.id);
    });
    return List.unmodifiable(list);
  }

  @override
  Stream<List<Movement>> watchMovements(String groupId) async* {
    try {
      yield* _collection(
        groupId,
      ).snapshots(includeMetadataChanges: true).map((s) => _list(groupId, s));
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<List<Movement>> loadMovements(String groupId) async {
    try {
      return _list(
        groupId,
        await _collection(groupId).get(const GetOptions(source: Source.server)),
      );
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  Map<String, Object?> _fields(String actorUid, MovementInput input) => {
    'type': input.type.name,
    'amountCents': input.amountCents,
    'status': 'active',
    'occurredAt': Timestamp.fromDate(input.occurredAt),
    'description': input.description,
    'personId': input.personId,
    if (input.refund != null) 'refund': input.refund!.toMap(),
    'createdBy': actorUid,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
  @override
  Stream<MovementCashTotals> watchCash(
    String groupId,
    String uid,
    DateTime monthStart,
  ) =>
      FirestoreCashAggregateService(_firestore).watch(groupId, uid, monthStart);
  @override
  Future<void> clearCashAccount(String uid) => FileCashCache().clear(uid);
  @override
  Stream<List<Movement>> watchRecent(String groupId) async* {
    try {
      yield* _collection(groupId)
          .orderBy('updatedAt', descending: true)
          .limit(20)
          .snapshots(includeMetadataChanges: true)
          .asyncMap((snapshot) async {
            final rows = _list(groupId, snapshot),
                known = rows.map((m) => m.id).toSet();
            final missing = <String>{
              for (final row in rows) ...[
                if (row.correctionOfMovementId != null)
                  row.correctionOfMovementId!,
                if (row.correctedByMovementId != null)
                  row.correctedByMovementId!,
              ],
            }.difference(known);
            if (missing.isEmpty) return rows;
            final combined = <Movement>[...rows], ids = missing.toList();
            for (var offset = 0; offset < ids.length; offset += 30) {
              final query = _collection(groupId).where(
                FieldPath.documentId,
                whereIn: ids.skip(offset).take(30).toList(),
              );
              final pairs = await query.get(
                GetOptions(
                  source: snapshot.metadata.isFromCache
                      ? Source.cache
                      : Source.server,
                ),
              );
              combined.addAll(_list(groupId, pairs));
            }
            return List<Movement>.unmodifiable(combined);
          });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Stream<List<Movement>> watchQuotaSources(String groupId) {
    late final StreamController<List<Movement>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? incomes, refunds;
    StreamSubscription<void>? synchronized;
    List<Movement>? incomeRows, refundRows;
    void emit() {
      if (incomeRows != null && refundRows != null) {
        controller.add(
          List<Movement>.unmodifiable([...incomeRows!, ...refundRows!]),
        );
      }
    }

    void error(Object e, StackTrace stack) =>
        controller.addError(e is FirebaseException ? _failure(e) : e, stack);
    controller = StreamController(
      onListen: () {
        incomes = _collection(groupId)
            .where('type', isEqualTo: 'income')
            .snapshots(includeMetadataChanges: true)
            .listen((snapshot) {
              try {
                incomeRows = _list(groupId, snapshot);
              } catch (e, s) {
                controller.addError(e, s);
              }
            }, onError: error);
        refunds = _collection(groupId)
            .where('refund.incomeId', isGreaterThan: '')
            .snapshots(includeMetadataChanges: true)
            .listen((snapshot) {
              try {
                refundRows = _list(groupId, snapshot);
              } catch (e, s) {
                controller.addError(e, s);
              }
            }, onError: error);
        synchronized = _firestore.snapshotsInSync().listen(
          (_) => emit(),
          onError: error,
        );
      },
      onCancel: () async {
        await incomes?.cancel();
        await refunds?.cancel();
        await synchronized?.cancel();
      },
    );
    return controller.stream;
  }

  bool _same(Map<String, dynamic> data, String actorUid, MovementInput input) =>
      data['createdBy'] == actorUid &&
      data['type'] == input.type.name &&
      data['amountCents'] == input.amountCents &&
      data['personId'] == input.personId &&
      data['description'] == input.description &&
      (input.refund == null
          ? data['refund'] == null
          : input.refund!.sameAs(RefundPlan.fromMap(data['refund']))) &&
      data['occurredAt'] == Timestamp.fromDate(input.occurredAt);
  @override
  Future<void> save(
    String groupId,
    String id,
    String actorUid,
    MovementInput input, {
    Movement? original,
    String? reason,
  }) => _save(groupId, id, actorUid, input, original: original, reason: reason);

  @override
  Future<void> saveWithInitialQuota(
    String groupId,
    String id,
    String actorUid,
    MovementInput input,
    InitialQuotaAssignment assignment,
  ) => _save(groupId, id, actorUid, input, initialQuota: assignment);

  @override
  Future<bool> initialQuotaApplied(
    String groupId,
    String id,
    String actorUid,
    InitialQuotaAssignment assignment,
  ) async {
    try {
      final audit = await _firestore
          .doc(
            FirestorePaths.auditEvent(
              groupId,
              FirestoreInitialQuotaMutation.auditId(id, assignment),
            ),
          )
          .get(const GetOptions(source: Source.server));
      return FirestoreInitialQuotaMutation.matches(
        audit.data(),
        actorUid,
        id,
        assignment,
      );
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  Future<void> _save(
    String groupId,
    String id,
    String actorUid,
    MovementInput input, {
    Movement? original,
    String? reason,
    InitialQuotaAssignment? initialQuota,
  }) async {
    try {
      final target = _collection(groupId).doc(id);
      await _firestore.runTransaction((tx) async {
        final existing = (await tx.get(target)).data();
        final writeQuota = initialQuota == null
            ? null
            : await FirestoreInitialQuotaMutation.prepare(
                _firestore,
                tx,
                groupId: groupId,
                movementId: id,
                actorUid: actorUid,
                input: input,
                assignment: initialQuota,
                existing: existing != null,
              );
        if (original == null) {
          if (existing != null) {
            if (!_same(existing, actorUid, input) ||
                existing['correctionOfMovementId'] != null) {
              throw _conflict;
            }
            return;
          }
          final refund = await FirestoreRefundMutation.prepare(
            _firestore,
            tx,
            groupId: groupId,
            actorUid: actorUid,
            kind: 'create',
            originalId: null,
            targetId: id,
            before: null,
            after: input.refund,
            personId: input.personId,
          );
          final history = await FirestoreMovementTrace.prepareHistory(
            _firestore,
            tx,
            groupId,
            id,
            input.personId,
            actorUid,
          );
          final fields = {
            ..._fields(actorUid, input),
            if (refund != null) 'lastRefundOperationId': refund.operationId,
          };
          tx.set(target, fields);
          history();
          if (input.refund == null) {
            FirestoreMovementTrace.write(
              _firestore,
              tx,
              groupId,
              id,
              actorUid,
              'created',
              null,
              fields,
            );
          }
          refund?.write(tx);
          writeQuota?.call();
          return;
        }
        final source = _collection(groupId).doc(original.id);
        final before = (await tx.get(source)).data();
        if (existing != null) {
          if (!_same(existing, actorUid, input) ||
              existing['correctionOfMovementId'] != original.id ||
              before?['status'] != 'corrected' ||
              before?['correctedByMovementId'] != id ||
              before?['correctionReason'] != reason) {
            throw _conflict;
          }
          return;
        }
        if (before?['status'] != 'active' ||
            before?['updatedAt'] != Timestamp.fromDate(original.updatedAt)) {
          throw _conflict;
        }
        await _checkIncomeRefunds(tx, groupId, original.id, before!);
        final previousRefund = RefundPlan.fromMap(before['refund']);
        final refund = await FirestoreRefundMutation.prepare(
          _firestore,
          tx,
          groupId: groupId,
          actorUid: actorUid,
          kind: 'correct',
          originalId: original.id,
          targetId: id,
          before: previousRefund,
          after: input.refund,
          personId: previousRefund == null
              ? input.personId
              : before['personId'] as String?,
        );
        if (previousRefund != null &&
            input.refund != null &&
            before['personId'] != input.personId) {
          throw _conflict;
        }
        final history = await FirestoreMovementTrace.prepareHistory(
          _firestore,
          tx,
          groupId,
          id,
          input.personId,
          actorUid,
        );
        final sourceFields = {
          'status': 'corrected',
          'updatedAt': FieldValue.serverTimestamp(),
          'correctedAt': FieldValue.serverTimestamp(),
          'correctedBy': actorUid,
          'correctionReason': reason,
          'correctedByMovementId': id,
          if (refund != null) 'lastRefundOperationId': refund.operationId,
        };
        tx.update(source, sourceFields);
        final targetFields = {
          ..._fields(actorUid, input),
          'correctionOfMovementId': original.id,
          if (refund != null) 'lastRefundOperationId': refund.operationId,
        };
        tx.set(target, targetFields);
        history();
        if (previousRefund == null) {
          FirestoreMovementTrace.write(
            _firestore,
            tx,
            groupId,
            original.id,
            actorUid,
            'corrected',
            before,
            {...before, ...sourceFields},
          );
        }
        if (input.refund == null) {
          FirestoreMovementTrace.write(
            _firestore,
            tx,
            groupId,
            id,
            actorUid,
            'created',
            null,
            targetFields,
          );
        }
        refund?.write(tx);
      });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> cancel(
    String groupId,
    Movement movement,
    String actorUid,
    String reason,
  ) async {
    try {
      final target = _collection(groupId).doc(movement.id);
      await _firestore.runTransaction((tx) async {
        final data = (await tx.get(target)).data();
        if (data?['status'] == 'cancelled' &&
            data?['cancelledBy'] == actorUid &&
            data?['cancellationReason'] == reason) {
          return;
        }
        if (data?['status'] != 'active' ||
            data?['updatedAt'] != Timestamp.fromDate(movement.updatedAt)) {
          throw _conflict;
        }
        await _checkIncomeRefunds(tx, groupId, movement.id, data!);
        final refund = await FirestoreRefundMutation.prepare(
          _firestore,
          tx,
          groupId: groupId,
          actorUid: actorUid,
          kind: 'cancel',
          originalId: movement.id,
          targetId: null,
          before: RefundPlan.fromMap(data['refund']),
          after: null,
          personId: data['personId'] as String?,
        );
        final fields = {
          'status': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelledBy': actorUid,
          'cancellationReason': reason,
          if (refund != null) 'lastRefundOperationId': refund.operationId,
        };
        tx.update(target, fields);
        if (data['refund'] == null) {
          FirestoreMovementTrace.write(
            _firestore,
            tx,
            groupId,
            movement.id,
            actorUid,
            'cancelled',
            data,
            {...data, ...fields},
          );
        }
        refund?.write(tx);
      });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  Future<void> _checkIncomeRefunds(
    Transaction tx,
    String groupId,
    String id,
    Map<String, dynamic> data,
  ) async {
    if (data['type'] != 'income') return;
    final balance = (await tx.get(
      _firestore.doc(FirestorePaths.allocationBalance(groupId, id)),
    )).data();
    if ((balance?['refundedCents'] as int? ?? 0) > 0) {
      throw const AppFailure(
        FailureCode.invalidData,
        'El ingreso tiene devoluciones activas. Revísalas antes de cambiar su origen.',
      );
    }
  }
}
