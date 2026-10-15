import '../core/errors/app_failure.dart';
import '../models/movement.dart';
import '../models/pending_movement.dart';
import '../services/pending_movement_service.dart';
import 'movement_repository.dart';

class MovementSubmissionRepository {
  MovementSubmissionRepository(this._journal, this._movements);
  final PendingMovementService _journal;
  final MovementRepository _movements;
  final Set<String> _busy = {};
  static const _pending = AppFailure(
    FailureCode.invalidData,
    'Hay un envío pendiente. Comprueba su resultado desde el inicio del grupo antes de registrar otro.',
  );
  static const _conflict = AppFailure(
    FailureCode.invalidData,
    'El movimiento ha cambiado o no coincide con este envío. Revisa el historial; no se enviará de nuevo.',
  );
  Future<PendingMovement?> pending(String uid, String groupId) =>
      _journal.read(uid, groupId);
  bool _sameInput(MovementInput a, MovementInput b) =>
      a.type == b.type &&
      a.amountCents == b.amountCents &&
      a.personId == b.personId &&
      a.description.trim() == b.description.trim() &&
      a.occurredAt.year == b.occurredAt.year &&
      a.occurredAt.month == b.occurredAt.month &&
      a.occurredAt.day == b.occurredAt.day;
  bool _same(PendingMovement a, PendingMovement b) =>
      a.id == b.id &&
      a.actorUid == b.actorUid &&
      a.groupId == b.groupId &&
      a.cancel == b.cancel &&
      a.original?.id == b.original?.id &&
      a.original?.updatedAt == b.original?.updatedAt &&
      a.reason?.trim() == b.reason?.trim() &&
      _sameInput(a.input, b.input);

  /// Returns true only when a server read proves this exact intention succeeded.
  /// Absence is not permission to silently repeat a financial operation.
  Future<bool> resolve(PendingMovement submission) async {
    final rows = await _movements.loadMovements(submission.groupId);
    Movement? target, original;
    for (final row in rows) {
      if (row.id == submission.id) target = row;
      if (row.id == submission.original?.id) original = row;
    }
    if (submission.cancel) {
      if (original == null) throw _conflict;
      if (original.status == MovementStatus.active) return false;
      if (original.status != MovementStatus.cancelled ||
          original.cancelledBy != submission.actorUid ||
          original.cancellationReason != submission.reason?.trim()) {
        throw _conflict;
      }
    } else {
      if (target == null) {
        if (submission.original != null &&
            (original?.status != MovementStatus.active ||
                original?.updatedAt != submission.original?.updatedAt)) {
          throw _conflict;
        }
        return false;
      }
      if (!_sameInput(target.input, submission.input) ||
          target.createdBy != submission.actorUid ||
          target.correctionOfMovementId != submission.original?.id) {
        throw _conflict;
      }
      if (submission.original != null &&
          (original?.status != MovementStatus.corrected ||
              original?.correctedByMovementId != submission.id ||
              original?.correctedBy != submission.actorUid ||
              original?.correctionReason != submission.reason?.trim())) {
        throw _conflict;
      }
    }
    await _journal.clear(
      submission.actorUid,
      submission.groupId,
      submission.id,
    );
    return true;
  }

  /// Explicitly forgets a local attempt, never cancels or deletes a server record.
  /// The caller must first show the history and require an explicit confirmation.
  Future<void> discard(PendingMovement submission) async {
    final key = '${submission.actorUid}/${submission.groupId}';
    if (!_busy.add(key)) throw _pending;
    try {
      final current = await pending(submission.actorUid, submission.groupId);
      if (current == null) return;
      if (!_same(current, submission)) throw _pending;
      try {
        if (await resolve(submission)) return;
      } on AppFailure catch (error) {
        if (error.code != FailureCode.invalidData) rethrow;
        // A conflicting server result requires manual reconciliation, not a replay.
      }
      await _journal.clear(
        submission.actorUid,
        submission.groupId,
        submission.id,
      );
    } finally {
      _busy.remove(key);
    }
  }

  Future<void> submit(PendingMovement submission, {DateTime? today}) async {
    final error = submission.cancel
        ? MovementRepository.reasonError(submission.reason)
        : MovementRepository.inputError(submission.input, today: today) ??
              (submission.original == null
                  ? null
                  : MovementRepository.reasonError(submission.reason));
    if (error != null) throw AppFailure(FailureCode.invalidData, error);
    if ((submission.cancel && submission.original == null) ||
        (submission.original != null &&
            submission.original?.groupId != submission.groupId)) {
      throw _conflict;
    }
    final key = '${submission.actorUid}/${submission.groupId}';
    if (!_busy.add(key)) throw _pending;
    try {
      final previous = await pending(submission.actorUid, submission.groupId);
      if (previous != null && !_same(previous, submission)) throw _pending;
      if (previous == null) await _journal.write(submission);
      // If acknowledgement was lost, check the server before invoking a write again.
      if (previous != null && await resolve(previous)) return;
      if (submission.cancel) {
        final original = submission.original;
        if (original == null) throw _conflict;
        await _movements.cancel(
          submission.groupId,
          original,
          submission.actorUid,
          submission.reason ?? '',
        );
      } else {
        await _movements.save(
          submission.groupId,
          submission.id,
          submission.actorUid,
          submission.input,
          original: submission.original,
          reason: submission.reason,
          today: today,
        );
      }
      await _journal.clear(
        submission.actorUid,
        submission.groupId,
        submission.id,
      );
    } finally {
      _busy.remove(key);
    }
  }
}
