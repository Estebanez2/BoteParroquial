import 'movement.dart';

enum DashboardActivityKind { registered, cancelled, corrected }

class DashboardActivity {
  const DashboardActivity({
    required this.movementId,
    required this.kind,
    required this.at,
    required this.actorUid,
    required this.input,
    this.reason,
  });
  final String movementId, actorUid;
  final DashboardActivityKind kind;
  final DateTime at;
  final MovementInput input;
  final String? reason;
}

class DashboardSummary {
  DashboardSummary({
    required this.groupId,
    required this.incomeCents,
    required this.withdrawalCents,
    required this.activePersonsCount,
    required this.inactivePersonsCount,
    required List<DashboardActivity> recentActivity,
  }) : recentActivity = List.unmodifiable(recentActivity);
  final String groupId;
  final int incomeCents,
      withdrawalCents,
      activePersonsCount,
      inactivePersonsCount;
  final List<DashboardActivity> recentActivity;
  int get balanceCents => incomeCents - withdrawalCents;
  int get totalPersonsCount => activePersonsCount + inactivePersonsCount;
  bool get isNegative => balanceCents < 0;
}
