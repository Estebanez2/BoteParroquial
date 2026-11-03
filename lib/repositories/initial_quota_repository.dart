import '../core/errors/app_failure.dart';
import '../models/initial_quota_assignment.dart';
import '../models/participation_period.dart';
import '../models/quota_rule.dart';
import '../models/quota_settlement.dart';
import '../models/year_month.dart';
import 'quota_repository.dart';

abstract final class InitialQuotaRepository {
  static ({
    InitialQuotaAssignment assignment,
    int overpaymentCents,
    int? expectedCents,
  })
  review({
    required String groupId,
    required String personId,
    required YearMonth month,
    required int? cents,
    required int incomeCents,
    required List<ParticipationPeriod> periods,
    required List<QuotaRule> rules,
    required PersonQuotaSettlement settlement,
  }) {
    if (cents == null ||
        cents <= 0 ||
        cents > incomeCents ||
        periods.any((p) => p.groupId != groupId || p.personId != personId) ||
        rules.any((r) => r.groupId != groupId)) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Indica un importe mayor que cero que no supere el ingreso.',
      );
    }
    final period = periods.where((p) => p.includes(month)).firstOrNull;
    if (period == null) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Configura una etapa de participación que incluya este mes antes de asignarle una cuota.',
      );
    }
    final expected = QuotaRepository.atMonth(rules, month)?.monthlyFeeCents;
    final paid =
        settlement.months
            .where((m) => m.month == month)
            .firstOrNull
            ?.allocatedCents ??
        0;
    return (
      assignment: InitialQuotaAssignment(
        month: month,
        amountCents: cents,
        participationPeriodId: period.id,
      ),
      expectedCents: expected,
      overpaymentCents: expected != null && paid + cents > expected
          ? paid + cents - expected
          : 0,
    );
  }
}
