import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';
import '../models/quota_rule.dart';
import '../models/year_month.dart';
import 'quota_service.dart';

class FirestoreQuotaService implements QuotaService {
  const FirestoreQuotaService(this._db);
  final FirebaseFirestore _db;
  static QuotaRule _parse(
    String groupId,
    String id,
    Map<String, dynamic> data,
  ) {
    final ordinal = data['effectiveFromMonth'],
        cents = data['monthlyFeeCents'],
        revision = data['revision'];
    if (ordinal is! int ||
        ordinal < 24000 ||
        ordinal > 25211 ||
        cents is! int ||
        cents < 0 ||
        cents > 99999999999999 ||
        revision is! int ||
        revision < 1) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Una regla de cuota tiene datos no válidos.',
      );
    }
    return QuotaRule(
      id: id,
      groupId: groupId,
      effectiveFrom: YearMonth(ordinal ~/ 12, ordinal % 12 + 1),
      monthlyFeeCents: cents,
      revision: revision,
    );
  }

  static AppFailure failure(FirebaseException error) => switch (error.code) {
    'permission-denied' || 'unauthenticated' => const AppFailure(
      FailureCode.permissionDenied,
      'No se pudo autorizar el cambio de cuotas o participación. Actualiza el grupo.',
    ),
    'unavailable' || 'deadline-exceeded' => const AppFailure(
      FailureCode.network,
      'Se necesita conexión. Revisa el historial antes de repetir el cambio.',
    ),
    _ => const AppFailure(
      FailureCode.unknown,
      'No se pudo confirmar el cambio. Actualiza antes de repetirlo.',
    ),
  };
  Stream<List<QuotaRule>> _watch(
    String groupId,
    Query<Map<String, dynamic>> query,
  ) async* {
    try {
      yield* query
          .snapshots(includeMetadataChanges: true)
          .map(
            (snapshot) => List.unmodifiable(
              snapshot.docs
                  .where((d) => !d.metadata.hasPendingWrites)
                  .map((d) => _parse(groupId, d.id, d.data())),
            ),
          );
    } on FirebaseException catch (error) {
      throw failure(error);
    }
  }

  @override
  Stream<List<QuotaRule>> watchRules(String groupId) => _watch(
    groupId,
    _db
        .collection(FirestorePaths.quotaRules(groupId))
        .orderBy('effectiveFromMonth'),
  );
  @override
  Stream<List<QuotaRule>> watchVersions(String groupId, String ruleId) =>
      _watch(
        groupId,
        _db
            .doc(FirestorePaths.quotaRule(groupId, ruleId))
            .collection('versions')
            .orderBy('revision', descending: true)
            .limit(20),
      );
  @override
  Future<void> saveRule(
    String groupId,
    String actorUid,
    YearMonth month,
    int cents,
    QuotaRule? original,
  ) async {
    final root = _db.doc(
      FirestorePaths.quotaRule(groupId, month.ordinal.toString()),
    );
    final settings = _db.doc(FirestorePaths.quotaSettings(groupId));
    final audit = _db.collection(FirestorePaths.auditEvents(groupId)).doc();
    try {
      await _db.runTransaction((tx) async {
        final previous = (await tx.get(root)).data();
        final config = (await tx.get(settings)).data();
        if ((previous == null) != (original == null) ||
            (previous != null && previous['revision'] != original?.revision)) {
          throw const AppFailure(
            FailureCode.invalidData,
            'La cuota ha cambiado. Revisa el historial antes de guardar.',
          );
        }
        final now = FieldValue.serverTimestamp();
        final revision = (previous?['revision'] as int? ?? 0) + 1;
        final after = {
          'effectiveFromMonth': month.ordinal,
          'monthlyFeeCents': cents,
          'revision': revision,
        };
        tx.set(root, {
          ...after,
          'createdBy': previous?['createdBy'] ?? actorUid,
          'createdAt': previous?['createdAt'] ?? now,
          'updatedBy': actorUid,
          'updatedAt': now,
          'lastAuditEventId': audit.id,
        });
        tx.set(root.collection('versions').doc(audit.id), {
          ...after,
          'actorUid': actorUid,
          'createdAt': now,
        });
        if (config == null) {
          tx.set(settings, {
            'firstMonth': month.ordinal,
            'createdBy': actorUid,
            'createdAt': now,
          });
        }
        tx.set(audit, {
          'action': 'quota.changed',
          'entityType': 'quotaRule',
          'entityId': root.id,
          'actorUid': actorUid,
          'createdAt': now,
          'before': previous == null
              ? null
              : {
                  'effectiveFromMonth': previous['effectiveFromMonth'],
                  'monthlyFeeCents': previous['monthlyFeeCents'],
                  'revision': previous['revision'],
                },
          'after': after,
        });
      });
    } on FirebaseException catch (error) {
      throw failure(error);
    }
  }
}
