enum MovementType { income, withdrawal }

enum MovementStatus { active, cancelled, corrected }

class MovementInput {
  const MovementInput({
    required this.type,
    required this.amountCents,
    required this.occurredAt,
    required this.description,
    this.personId,
  });
  final MovementType type;
  final int amountCents;
  final DateTime occurredAt;
  final String description;
  final String? personId;
  int get signedCents =>
      type == MovementType.income ? amountCents : -amountCents;
}

class Movement {
  const Movement({
    required this.id,
    required this.groupId,
    required this.input,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.cancelledBy,
    this.cancelledAt,
    this.cancellationReason,
    this.correctedBy,
    this.correctedAt,
    this.correctionReason,
    this.correctedByMovementId,
    this.correctionOfMovementId,
  });
  final String id, groupId, createdBy;
  final MovementInput input;
  final MovementStatus status;
  final DateTime createdAt, updatedAt;
  final String? cancelledBy, cancellationReason, correctedBy, correctionReason;
  final DateTime? cancelledAt, correctedAt;
  final String? correctedByMovementId, correctionOfMovementId;
  int get contributionCents =>
      status == MovementStatus.active ? input.signedCents : 0;
}

class MovementReview {
  const MovementReview({
    required this.balanceCents,
    required this.projectedCents,
    required this.inactivePerson,
  });
  final int balanceCents, projectedCents;
  final bool inactivePerson;
  bool get needsNegativeConfirmation => projectedCents < 0;
}
