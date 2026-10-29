import 'movement.dart';
import 'year_month.dart';

/// One income's current allocation to one month; earlier revisions live in audit.
final class QuotaAllocation {
  const QuotaAllocation({
    required this.id,
    required this.groupId,
    required this.movementId,
    required this.personId,
    required this.month,
    required this.amountCents,
    required this.revision,
    required this.participationPeriodId,
  });
  final String id, groupId, movementId, personId, participationPeriodId;
  final YearMonth month;
  final int amountCents, revision;
}

final class AllocationChange {
  const AllocationChange({
    required this.operationId,
    required this.actorUid,
    required this.movement,
    required this.month,
    required this.amountCents,
    required this.participationPeriodId,
    this.previous,
  });
  final String operationId, actorUid, participationPeriodId;
  final Movement movement;
  final YearMonth month;
  final int amountCents;
  final QuotaAllocation? previous;
}

final class AllocationReview {
  const AllocationReview({
    required this.change,
    required this.overpaymentCents,
    required this.expectedCents,
  });
  final AllocationChange change;
  final int overpaymentCents;
  final int? expectedCents;
}

final class AllocationSuggestion {
  const AllocationSuggestion({required this.month, required this.amountCents});
  final YearMonth month;

  /// Final amount for this income/month, including any previous allocation.
  final int amountCents;
}
