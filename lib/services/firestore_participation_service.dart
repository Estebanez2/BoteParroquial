import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';
import '../models/person.dart';
import '../models/participation_period.dart';
import '../models/year_month.dart';
import 'participation_service.dart';
import 'firestore_quota_service.dart';

class FirestoreParticipationService implements ParticipationService {
  const FirestoreParticipationService(this._db);
  final FirebaseFirestore _db;
  static YearMonth _month(Object? raw) {
    if (raw is! int || raw < 24000 || raw > 25211) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Un periodo de participación tiene meses no válidos.',
      );
    }
    return YearMonth(raw ~/ 12, raw % 12 + 1);
  }

  static ParticipationPeriod parsePeriod(
    String groupId,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data(), personId = data['personId'];
    if (personId is! String || personId.isEmpty) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Un periodo no identifica a su persona.',
      );
    }
    return ParticipationPeriod(
      id: doc.id,
      groupId: groupId,
      personId: personId,
      firstMonth: _month(data['firstMonth']),
      lastMonthInclusive: data['lastMonthInclusive'] == null
          ? null
          : _month(data['lastMonthInclusive']),
    );
  }

  @override
  Stream<List<ParticipationPeriod>> watchPeriods(
    String groupId,
    String personId,
  ) async* {
    try {
      yield* _db
          .collection(FirestorePaths.participationPeriods(groupId))
          .where('personId', isEqualTo: personId)
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) {
            final periods =
                snapshot.docs.where((d) => !d.metadata.hasPendingWrites).map((
                  d,
                ) {
                  return parsePeriod(groupId, d);
                }).toList()..sort();
            return List<ParticipationPeriod>.unmodifiable(periods);
          });
    } on FirebaseException catch (error) {
      throw FirestoreQuotaService.failure(error);
    }
  }

  @override
  Future<void> change(
    String groupId,
    String actorUid,
    Person person,
    ParticipationPeriod? previous,
    YearMonth month,
    bool starting,
  ) async {
    final personRef = _db.doc(FirestorePaths.person(groupId, person.id));
    final periodRef = starting
        ? _db.collection(FirestorePaths.participationPeriods(groupId)).doc()
        : _db.doc(FirestorePaths.participationPeriod(groupId, previous!.id));
    final audit = _db.collection(FirestorePaths.auditEvents(groupId)).doc();
    try {
      await _db.runTransaction((tx) async {
        final data = (await tx.get(personRef)).data();
        final beforePeriod = previous == null
            ? null
            : (await tx.get(
                _db.doc(
                  FirestorePaths.participationPeriod(groupId, previous.id),
                ),
              )).data();
        final uid = data?['linkedUid'] as String?;
        final memberRef = !starting && uid != null
            ? _db.doc(FirestorePaths.member(groupId, uid))
            : null;
        final member = memberRef == null
            ? null
            : (await tx.get(memberRef)).data();
        if (data == null ||
            data['updatedAt'] != Timestamp.fromDate(person.updatedAt) ||
            data['lastParticipationPeriodId'] != previous?.id ||
            (previous != null &&
                (beforePeriod == null ||
                    beforePeriod['firstMonth'] != previous.firstMonth.ordinal ||
                    beforePeriod['lastMonthInclusive'] !=
                        previous.lastMonthInclusive?.ordinal))) {
          throw const AppFailure(
            FailureCode.invalidData,
            'La persona o su periodo han cambiado. Vuelve a abrir su ficha.',
          );
        }
        final now = FieldValue.serverTimestamp();
        final demotes = !starting && member?['role'] == 'admin';
        if (starting) {
          tx.set(periodRef, {
            'personId': person.id,
            'firstMonth': month.ordinal,
            'lastMonthInclusive': null,
            'createdAt': now,
            'createdBy': actorUid,
            'updatedAt': now,
            'updatedBy': actorUid,
            'lastAuditEventId': audit.id,
          });
        } else {
          tx.update(periodRef, {
            'lastMonthInclusive': month.ordinal,
            'updatedAt': now,
            'updatedBy': actorUid,
            'lastAuditEventId': audit.id,
          });
        }
        tx.update(personRef, {
          'isActive': starting,
          'lastParticipationPeriodId': periodRef.id,
          'updatedAt': now,
          'updatedBy': actorUid,
          'lastAuditEventId': audit.id,
        });
        if (demotes && memberRef != null) {
          tx.update(memberRef, {
            'role': 'member',
            'updatedAt': now,
            'lastAuditEventId': audit.id,
          });
        }
        tx.set(audit, {
          'action': starting ? 'participation.started' : 'person.inactivated',
          'entityType': 'person',
          'entityId': person.id,
          'actorUid': actorUid,
          'createdAt': now,
          'before': starting
              ? {'periodId': previous?.id, 'isActive': person.isActive}
              : {
                  'isActive': true,
                  'linkedUid': uid,
                  'role': member?['role'],
                  'periodId': previous!.id,
                  'firstMonth': previous.firstMonth.ordinal,
                  'lastMonthInclusive': null,
                },
          'after': starting
              ? {
                  'periodId': periodRef.id,
                  'firstMonth': month.ordinal,
                  'isActive': true,
                }
              : {
                  'isActive': false,
                  'linkedUid': uid,
                  'role': demotes ? 'member' : member?['role'],
                  'periodId': previous!.id,
                  'firstMonth': previous.firstMonth.ordinal,
                  'lastMonthInclusive': month.ordinal,
                },
        });
      });
    } on FirebaseException catch (error) {
      throw FirestoreQuotaService.failure(error);
    }
  }
}
