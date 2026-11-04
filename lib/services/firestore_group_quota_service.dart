import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';
import '../models/participation_period.dart';
import '../models/quota_allocation.dart';
import 'firestore_allocation_service.dart';
import 'firestore_participation_service.dart';
import 'group_quota_service.dart';

final class FirestoreGroupQuotaService implements GroupQuotaService {
  const FirestoreGroupQuotaService(this._store);
  final FirebaseFirestore _store;
  static AppFailure _failure(FirebaseException e) => switch (e.code) {
    'resource-exhausted' => firestoreQuotaFailure,
    'permission-denied' || 'unauthenticated' => const AppFailure(
      FailureCode.permissionDenied,
      'No se puede consultar el cumplimiento sin acceso al grupo.',
    ),
    'unavailable' || 'deadline-exceeded' => const AppFailure(
      FailureCode.network,
      'No se pudieron consultar las cuotas. Revisa la conexión y actualiza.',
    ),
    _ => const AppFailure(
      FailureCode.unknown,
      'No se pudo preparar el resumen de cuotas.',
    ),
  };
  @override
  Stream<List<ParticipationPeriod>> watchPeriods(String groupId) async* {
    try {
      yield* _store
          .collection(FirestorePaths.participationPeriods(groupId))
          .snapshots(includeMetadataChanges: true)
          .map(
            (s) => List<ParticipationPeriod>.unmodifiable(
              s.docs
                  .where((d) => !d.metadata.hasPendingWrites)
                  .map(
                    (d) =>
                        FirestoreParticipationService.parsePeriod(groupId, d),
                  ),
            ),
          );
    } on FirebaseException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Stream<List<QuotaAllocation>> watchAllocations(String groupId) async* {
    try {
      yield* _store
          .collection(FirestorePaths.allocations(groupId))
          .snapshots(includeMetadataChanges: true)
          .map(
            (s) => List<QuotaAllocation>.unmodifiable(
              s.docs
                  .where((d) => !d.metadata.hasPendingWrites)
                  .map(
                    (d) =>
                        FirestoreAllocationService.parseAllocation(groupId, d),
                  ),
            ),
          );
    } on FirebaseException catch (e) {
      throw _failure(e);
    }
  }
}
