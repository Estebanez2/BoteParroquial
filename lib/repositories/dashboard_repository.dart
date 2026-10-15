import '../core/errors/app_failure.dart';
import '../models/dashboard_summary.dart';
import '../models/movement.dart';
import '../models/person.dart';
import 'movement_repository.dart';

/// Pure projection: reusable by any UI, without Flutter or Firebase dependencies.
class DashboardRepository {
  const DashboardRepository();
  static const recentLimit = 5;
  DashboardSummary summarize(
    String groupId,
    List<Movement> movements,
    List<Person> persons,
  ) {
    if (movements.any((m) => m.groupId != groupId) ||
        persons.any((p) => p.groupId != groupId)) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'El resumen contiene datos de otro grupo.',
      );
    }
    var income = 0, withdrawal = 0, activePersons = 0;
    final activity = <DashboardActivity>[];
    final byId = {for (final movement in movements) movement.id: movement};
    for (final movement in movements) {
      if (movement.input.amountCents <= 0 ||
          movement.input.amountCents > MovementRepository.maximumCents) {
        throw const AppFailure(
          FailureCode.invalidData,
          'Un movimiento tiene un importe no válido.',
        );
      }
      if (movement.status == MovementStatus.active) {
        switch (movement.input.type) {
          case MovementType.income:
            income += movement.input.amountCents;
          case MovementType.withdrawal:
            withdrawal += movement.input.amountCents;
        }
      }
      final original = byId[movement.correctionOfMovementId];
      // The original already represents this correction, so don't duplicate its
      // active replacement as a second "registered" event at the same time.
      if (movement.status == MovementStatus.active &&
          original?.status == MovementStatus.corrected &&
          original?.correctedByMovementId == movement.id) {
        continue;
      }
      final replacement = byId[movement.correctedByMovementId];
      activity.add(switch (movement.status) {
        MovementStatus.active => DashboardActivity(
          movementId: movement.id,
          kind: DashboardActivityKind.registered,
          at: movement.createdAt,
          actorUid: movement.createdBy,
          input: movement.input,
        ),
        MovementStatus.cancelled => DashboardActivity(
          movementId: movement.id,
          kind: DashboardActivityKind.cancelled,
          at: movement.cancelledAt ?? movement.updatedAt,
          actorUid: movement.cancelledBy ?? movement.createdBy,
          input: movement.input,
          reason: movement.cancellationReason,
        ),
        MovementStatus.corrected => DashboardActivity(
          movementId: movement.id,
          kind: DashboardActivityKind.corrected,
          at: movement.correctedAt ?? movement.updatedAt,
          actorUid: movement.correctedBy ?? movement.createdBy,
          input: replacement?.input ?? movement.input,
          reason: movement.correctionReason,
        ),
      });
    }
    for (final person in persons) {
      if (person.isActive) activePersons++;
    }
    activity.sort((a, b) {
      final date = b.at.compareTo(a.at);
      return date != 0 ? date : a.movementId.compareTo(b.movementId);
    });
    return DashboardSummary(
      groupId: groupId,
      incomeCents: income,
      withdrawalCents: withdrawal,
      activePersonsCount: activePersons,
      inactivePersonsCount: persons.length - activePersons,
      recentActivity: activity.take(recentLimit).toList(),
    );
  }
}
