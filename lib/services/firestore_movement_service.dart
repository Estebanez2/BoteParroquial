import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';
import '../models/movement.dart';
import 'movement_service.dart';

class FirestoreMovementService implements MovementService {
  const FirestoreMovementService(this._firestore);
  final FirebaseFirestore _firestore;
  static const _conflict = AppFailure(
    FailureCode.invalidData,
    'El movimiento ya ha cambiado o este envío ya existe con otros datos. Revisa el historial.',
  );
  static const _invalid = AppFailure(
    FailureCode.invalidData,
    'Un movimiento tiene un formato no válido.',
  );
  static AppFailure _failure(FirebaseException error) => switch (error.code) {
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
    'createdBy': actorUid,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
  bool _same(Map<String, dynamic> data, String actorUid, MovementInput input) =>
      data['createdBy'] == actorUid &&
      data['type'] == input.type.name &&
      data['amountCents'] == input.amountCents &&
      data['personId'] == input.personId &&
      data['description'] == input.description &&
      data['occurredAt'] == Timestamp.fromDate(input.occurredAt);
  @override
  Future<void> save(
    String groupId,
    String id,
    String actorUid,
    MovementInput input, {
    Movement? original,
    String? reason,
  }) async {
    try {
      final target = _collection(groupId).doc(id);
      await _firestore.runTransaction((tx) async {
        final existing = (await tx.get(target)).data();
        if (original == null) {
          if (existing != null) {
            if (!_same(existing, actorUid, input) ||
                existing['correctionOfMovementId'] != null) {
              throw _conflict;
            }
            return;
          }
          tx.set(target, _fields(actorUid, input));
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
        tx.update(source, {
          'status': 'corrected',
          'updatedAt': FieldValue.serverTimestamp(),
          'correctedAt': FieldValue.serverTimestamp(),
          'correctedBy': actorUid,
          'correctionReason': reason,
          'correctedByMovementId': id,
        });
        tx.set(target, {
          ..._fields(actorUid, input),
          'correctionOfMovementId': original.id,
        });
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
        tx.update(target, {
          'status': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelledBy': actorUid,
          'cancellationReason': reason,
        });
      });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }
}
