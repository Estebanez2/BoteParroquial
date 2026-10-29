import 'year_month.dart';

enum QuotaReminderStage { sevenDaysBeforeEnd, oneDayBeforeEnd }

/// An obligation to review before delivery, not a resolved push recipient.
final class QuotaReminderCandidate {
  const QuotaReminderCandidate({
    required this.personId,
    required this.expectedCents,
    required this.paidCents,
    required this.pendingCents,
  });

  final String personId;
  final int expectedCents, paidCents, pendingCents;
}

/// Pure preparation only. It neither persists notifications nor sends messages.
final class QuotaReminderPlan {
  QuotaReminderPlan({
    required this.groupId,
    required this.month,
    required this.stage,
    required Iterable<QuotaReminderCandidate> candidates,
    required Iterable<String> unconfiguredPersonIds,
  }) : candidates = List.unmodifiable(candidates),
       unconfiguredPersonIds = List.unmodifiable(unconfiguredPersonIds);

  final String groupId;
  final YearMonth month;
  final QuotaReminderStage stage;
  final List<QuotaReminderCandidate> candidates;

  /// Unknown configuration must not produce an invented debt or amount.
  final List<String> unconfiguredPersonIds;
}
