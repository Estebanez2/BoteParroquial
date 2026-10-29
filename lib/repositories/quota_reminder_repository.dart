import '../core/errors/app_failure.dart';
import '../models/quota_reminder.dart';
import '../models/quota_report.dart';
import '../models/year_month.dart';

/// Domain preparation shared independently of a future delivery backend.
final class QuotaReminderRepository {
  const QuotaReminderRepository();

  /// UTC encodes civil dates here, not the scheduled delivery instant.
  Map<QuotaReminderStage, DateTime> datesFor(YearMonth month) {
    final end = DateTime.utc(month.year, month.month + 1, 0);
    return Map.unmodifiable({
      QuotaReminderStage.sevenDaysBeforeEnd: end.subtract(
        const Duration(days: 7),
      ),
      QuotaReminderStage.oneDayBeforeEnd: end.subtract(const Duration(days: 1)),
    });
  }

  /// [groupToday] comes from the group's calendar, never the device timezone.
  /// A future backend must reload amounts, membership and preferences at send.
  QuotaReminderPlan? prepare({
    required String groupId,
    required DateTime groupToday,
    required QuotaReport monthlyReport,
  }) {
    final month = YearMonth.fromDate(groupToday);
    if (groupId.isEmpty ||
        monthlyReport.groupId != groupId ||
        monthlyReport.firstMonth != month ||
        monthlyReport.lastMonth != month ||
        monthlyReport.currentMonth != month ||
        monthlyReport.persons.any((p) => p.person.groupId != groupId)) {
      throw const AppFailure(
        FailureCode.invalidData,
        'El recordatorio necesita el informe del mes actual de este grupo.',
      );
    }
    final today = DateTime.utc(
      groupToday.year,
      groupToday.month,
      groupToday.day,
    );
    final stage = datesFor(month).entries
        .where((entry) => entry.value == today)
        .map((entry) => entry.key)
        .firstOrNull;
    if (stage == null) return null;

    final candidates = <QuotaReminderCandidate>[];
    final unconfigured = <String>[];
    for (final row in monthlyReport.persons) {
      // Full specification §20: inactive people stop receiving reminders.
      if (!row.person.isActive) continue;
      final totals = row.elapsed;
      if (!totals.isComplete) {
        unconfigured.add(row.person.id);
        continue;
      }
      if (totals.knownPendingCents <= 0) continue;
      candidates.add(
        QuotaReminderCandidate(
          personId: row.person.id,
          expectedCents: totals.knownExpectedCents,
          paidCents: totals.allocatedCents,
          pendingCents: totals.knownPendingCents,
        ),
      );
    }
    return QuotaReminderPlan(
      groupId: groupId,
      month: month,
      stage: stage,
      candidates: candidates,
      unconfiguredPersonIds: unconfigured,
    );
  }
}
