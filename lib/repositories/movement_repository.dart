import '../core/errors/app_failure.dart';
import '../models/movement.dart';
import '../models/person.dart';
import '../services/movement_service.dart';

class MovementRepository {
  const MovementRepository(this._service);
  final MovementService _service;
  static const maximumCents = 99999999999999;
  String newId(String groupId) => _service.newId(groupId);
  Stream<List<Movement>> watchMovements(String groupId) =>
      _service.watchMovements(groupId);
  Future<List<Movement>> loadMovements(String groupId) =>
      _service.loadMovements(groupId);
  static int balanceOf(Iterable<Movement> movements) =>
      movements.fold(0, (total, m) => total + m.contributionCents);
  static String? reasonError(String? value) =>
      value == null || value.trim().isEmpty
      ? 'Escribe el motivo.'
      : value.trim().length > 2000
      ? 'El motivo admite hasta 2000 caracteres.'
      : null;
  static String? inputError(MovementInput input) {
    if (input.amountCents <= 0 || input.amountCents > maximumCents) {
      return 'Introduce una cantidad mayor que cero y dentro del límite admitido.';
    }
    if (input.type == MovementType.income &&
        (input.personId?.isEmpty ?? true)) {
      return 'Selecciona la persona del ingreso.';
    }
    if (input.description.trim().length > 2000) {
      return 'La descripción admite hasta 2000 caracteres.';
    }
    if (input.type == MovementType.withdrawal &&
        input.description.trim().isEmpty) {
      return 'Escribe el motivo de la retirada.';
    }
    if (input.occurredAt.year < 2000 || input.occurredAt.year > 2100) {
      return 'Selecciona una fecha entre 2000 y 2100.';
    }
    final now = DateTime.now();
    if (DateTime.utc(
      input.occurredAt.year,
      input.occurredAt.month,
      input.occurredAt.day,
    ).isAfter(DateTime.utc(now.year, now.month, now.day))) {
      return 'La fecha efectiva debe ser hoy o un día anterior.';
    }
    return null;
  }

  static void _checkScope(String groupId, Movement movement) {
    if (movement.groupId != groupId) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'El movimiento pertenece a otro grupo.',
      );
    }
  }

  Future<MovementReview> review(
    String groupId,
    MovementInput? input,
    List<Person> persons, {
    Movement? original,
    bool cancel = false,
    String? reason,
    String? operationId,
    String? actorUid,
  }) async {
    if (original != null) _checkScope(groupId, original);
    final error = input == null ? null : inputError(input);
    if (error != null) throw AppFailure(FailureCode.invalidData, error);
    if (original != null) {
      final reasonFailure = reasonError(reason);
      if (reasonFailure != null) {
        throw AppFailure(FailureCode.invalidData, reasonFailure);
      }
    }
    Person? selected;
    if (input?.personId != null) {
      for (final person in persons) {
        if (person.groupId == groupId && person.id == input?.personId) {
          selected = person;
        }
      }
      if (selected == null) {
        throw const AppFailure(
          FailureCode.invalidData,
          'La persona ya no está disponible en este grupo.',
        );
      }
    }
    final movements = await _service.loadMovements(groupId);
    final balance = balanceOf(movements);
    Movement? previousSubmission;
    for (final movement in movements) {
      if (movement.id == operationId) previousSubmission = movement;
    }
    if (!cancel && previousSubmission != null && input != null) {
      final saved = previousSubmission.input;
      final same =
          previousSubmission.createdBy == actorUid &&
          saved.type == input.type &&
          saved.amountCents == input.amountCents &&
          saved.personId == input.personId &&
          saved.description == input.description.trim() &&
          saved.occurredAt ==
              DateTime.utc(
                input.occurredAt.year,
                input.occurredAt.month,
                input.occurredAt.day,
              ) &&
          previousSubmission.correctionOfMovementId == original?.id;
      if (!same) {
        throw const AppFailure(
          FailureCode.invalidData,
          'Este envío ya está registrado con otros datos. Revisa el historial.',
        );
      }
      return MovementReview(
        balanceCents: balance,
        projectedCents: balance,
        inactivePerson: selected?.isActive == false,
      );
    }
    Movement? current;
    if (original != null) {
      for (final movement in movements) {
        if (movement.id == original.id) current = movement;
      }
      if (cancel &&
          current?.status == MovementStatus.cancelled &&
          current?.cancelledBy == actorUid &&
          current?.cancellationReason == reason?.trim()) {
        return MovementReview(
          balanceCents: balance,
          projectedCents: balance,
          inactivePerson: false,
        );
      }
      if (current == null ||
          current.status != MovementStatus.active ||
          current.updatedAt != original.updatedAt) {
        throw const AppFailure(
          FailureCode.invalidData,
          'El movimiento ha cambiado. Vuelve al historial para actualizarlo.',
        );
      }
    }
    return MovementReview(
      balanceCents: balance,
      projectedCents:
          balance -
          (current?.contributionCents ?? 0) +
          (cancel ? 0 : input?.signedCents ?? 0),
      inactivePerson: selected?.isActive == false,
    );
  }

  Future<void> save(
    String groupId,
    String id,
    String actorUid,
    MovementInput input, {
    Movement? original,
    String? reason,
  }) {
    final error =
        inputError(input) ?? (original == null ? null : reasonError(reason));
    if (error != null) throw AppFailure(FailureCode.invalidData, error);
    if (original != null) _checkScope(groupId, original);
    final normalized = MovementInput(
      type: input.type,
      amountCents: input.amountCents,
      occurredAt: DateTime.utc(
        input.occurredAt.year,
        input.occurredAt.month,
        input.occurredAt.day,
      ),
      description: input.description.trim(),
      personId: input.personId,
    );
    return _service.save(
      groupId,
      id,
      actorUid,
      normalized,
      original: original,
      reason: reason?.trim(),
    );
  }

  Future<void> cancel(
    String groupId,
    Movement movement,
    String actorUid,
    String reason,
  ) {
    _checkScope(groupId, movement);
    final error = reasonError(reason);
    if (error != null) throw AppFailure(FailureCode.invalidData, error);
    return _service.cancel(groupId, movement, actorUid, reason.trim());
  }
}
