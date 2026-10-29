import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';
import '../models/person.dart';
import '../models/year_month.dart';
import 'person_service.dart';

class FirestorePersonService implements PersonService {
  const FirestorePersonService(this._firestore);
  final FirebaseFirestore _firestore;
  @override
  String newId(String groupId) =>
      _firestore.collection(FirestorePaths.persons(groupId)).doc().id;
  static AppFailure _failure(FirebaseException error) => switch (error.code) {
    'permission-denied' || 'unauthenticated' => const AppFailure(
      FailureCode.permissionDenied,
      'No tienes permiso para gestionar las personas de este grupo.',
    ),
    'unavailable' || 'deadline-exceeded' => const AppFailure(
      FailureCode.network,
      'No se pudo conectar. Comprueba la red y vuelve a intentarlo.',
    ),
    _ => const AppFailure(
      FailureCode.unknown,
      'No se pudo guardar el cambio. Inténtalo de nuevo.',
    ),
  };
  static Person parse(
    String groupId,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data['displayName'] is! String ||
        data['isActive'] is! bool ||
        data['createdBy'] is! String ||
        data['updatedBy'] is! String ||
        data['createdAt'] is! Timestamp ||
        data['updatedAt'] is! Timestamp ||
        (data['notes'] != null && data['notes'] is! String) ||
        (data['linkedUid'] != null && data['linkedUid'] is! String) ||
        (data['lastParticipationPeriodId'] != null &&
            data['lastParticipationPeriodId'] is! String)) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Una persona tiene datos no válidos.',
      );
    }
    return Person(
      id: doc.id,
      groupId: groupId,
      displayName: data['displayName'] as String,
      notes: data['notes'] as String?,
      linkedUid: data['linkedUid'] as String?,
      lastParticipationPeriodId: data['lastParticipationPeriodId'] as String?,
      isActive: data['isActive'] as bool,
      createdBy: data['createdBy'] as String,
      updatedBy: data['updatedBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate().toUtc(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate().toUtc(),
    );
  }

  @override
  Stream<List<Person>> watchPersons(String groupId) async* {
    try {
      yield* _firestore
          .collection(FirestorePaths.persons(groupId))
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) {
            // Pending server timestamps are not domain dates. Show confirmed records only.
            final persons = snapshot.docs
                .where((doc) => !doc.metadata.hasPendingWrites)
                .where((doc) => doc.data()['trashedAt'] == null)
                .map((doc) => parse(groupId, doc))
                .toList();
            persons.sort(
              (a, b) => a.displayName.toLowerCase().compareTo(
                b.displayName.toLowerCase(),
              ),
            );
            return List.unmodifiable(persons);
          });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> create(
    String groupId,
    String actorUid,
    String name,
    String? notes, {
    String? id,
    YearMonth? firstMonth,
  }) async {
    try {
      final person = _firestore
          .collection(FirestorePaths.persons(groupId))
          .doc(id);
      final data = <String, Object?>{
        'displayName': name,
        'notes': notes,
        'isActive': true,
        'createdBy': actorUid,
        'updatedBy': actorUid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'historyGuardVersion': 1,
      };
      if (firstMonth == null) {
        final audit = _firestore.doc(
          FirestorePaths.auditEvent(groupId, 'person-created-${person.id}'),
        );
        await _firestore.runTransaction((tx) async {
          final previous = (await tx.get(person)).data();
          final event = (await tx.get(audit)).data();
          if (previous != null || event != null) {
            if (previous != null &&
                event?['actorUid'] == actorUid &&
                event?['action'] == 'person.created' &&
                previous['displayName'] == name &&
                previous['notes'] == notes &&
                previous['createdBy'] == actorUid) {
              return;
            }
            throw const AppFailure(
              FailureCode.invalidData,
              'Este alta ya existe. Revisa el listado antes de repetir.',
            );
          }
          tx.set(person, {...data, 'lastAuditEventId': audit.id});
          tx.set(audit, {
            'action': 'person.created',
            'entityType': 'person',
            'entityId': person.id,
            'actorUid': actorUid,
            'createdAt': FieldValue.serverTimestamp(),
            'before': null,
            'after': {'displayName': name, 'notes': notes, 'isActive': true},
          });
        });
        return;
      }
      final period = _firestore.doc(
        FirestorePaths.participationPeriod(groupId, 'initial-${person.id}'),
      );
      final audit = _firestore.doc(
        FirestorePaths.auditEvent(groupId, 'person-created-${person.id}'),
      );
      final after = <String, Object?>{
        'displayName': name,
        'notes': notes,
        'periodId': period.id,
        'firstMonth': firstMonth.ordinal,
        'isActive': true,
      };
      await _firestore.runTransaction((tx) async {
        final previous = (await tx.get(person)).data();
        final event = (await tx.get(audit)).data();
        final previousPeriod = (await tx.get(period)).data();
        if (previous != null || event != null || previousPeriod != null) {
          final saved = event?['after'];
          if (previous != null &&
              previousPeriod != null &&
              event?['actorUid'] == actorUid &&
              event?['action'] == 'person.createdWithParticipation' &&
              event?['entityId'] == person.id &&
              saved is Map &&
              saved.length == after.length &&
              after.entries.every((e) => saved[e.key] == e.value)) {
            return;
          }
          throw const AppFailure(
            FailureCode.invalidData,
            'Este alta ya existe con otros datos. Revisa el listado antes de repetir.',
          );
        }
        final now = FieldValue.serverTimestamp();
        tx.set(person, {
          ...data,
          'lastParticipationPeriodId': period.id,
          'lastAuditEventId': audit.id,
        });
        tx.set(period, {
          'personId': person.id,
          'firstMonth': firstMonth.ordinal,
          'lastMonthInclusive': null,
          'createdBy': actorUid,
          'createdAt': now,
          'updatedBy': actorUid,
          'updatedAt': now,
          'lastAuditEventId': audit.id,
        });
        tx.set(audit, {
          'action': 'person.createdWithParticipation',
          'entityType': 'person',
          'entityId': person.id,
          'actorUid': actorUid,
          'createdAt': now,
          'before': null,
          'after': after,
        });
      });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  Future<void> _update(
    String groupId,
    String actorUid,
    Person person,
    Map<String, Object?> fields,
  ) async {
    try {
      final reference = _firestore.doc(
        FirestorePaths.person(groupId, person.id),
      );
      await _firestore.runTransaction((transaction) async {
        final current = (await transaction.get(reference)).data();
        if (current == null ||
            current['trashedAt'] != null ||
            current['updatedAt'] != Timestamp.fromDate(person.updatedAt)) {
          throw const AppFailure(
            FailureCode.invalidData,
            'Esta persona ha cambiado desde que la abriste. Cierra el panel y vuelve a abrirla para ver los datos actuales.',
          );
        }
        final inactivating =
            fields['isActive'] == false && current['isActive'] == true;
        if (fields.containsKey('isActive') &&
            current['lastParticipationPeriodId'] != null) {
          throw const AppFailure(
            FailureCode.invalidData,
            'Esta persona tiene cuotas configuradas. Elige su mes de baja o reincorporación desde la ficha.',
          );
        }
        final linkedUid = current['linkedUid'] as String?;
        final linkedMember = inactivating && linkedUid != null
            ? _firestore.doc(FirestorePaths.member(groupId, linkedUid))
            : null;
        final membership = linkedMember == null
            ? null
            : (await transaction.get(linkedMember)).data();
        final demotes = membership?['role'] == 'admin';
        final audit = _firestore
            .collection(FirestorePaths.auditEvents(groupId))
            .doc();
        final now = FieldValue.serverTimestamp();
        transaction.update(reference, {
          ...fields,
          'updatedBy': actorUid,
          'updatedAt': now,
          'lastAuditEventId': audit.id,
        });
        if (inactivating) {
          if (demotes && linkedMember != null) {
            transaction.update(linkedMember, {
              'role': 'member',
              'updatedAt': now,
              'lastAuditEventId': audit.id,
            });
          }
          transaction.set(audit, {
            'action': 'person.inactivated',
            'entityType': 'person',
            'entityId': person.id,
            'actorUid': actorUid,
            'createdAt': now,
            'before': {
              'isActive': true,
              'linkedUid': linkedUid,
              'role': membership?['role'],
            },
            'after': {
              'isActive': false,
              'linkedUid': linkedUid,
              'role': demotes ? 'member' : membership?['role'],
            },
          });
        } else {
          Map<String, Object?> summary(Map<String, dynamic> value) => {
            'displayName': value['displayName'],
            'notes': value['notes'],
            'isActive': value['isActive'],
          };
          transaction.set(audit, {
            'action': fields.containsKey('isActive')
                ? 'person.activated'
                : 'person.updated',
            'entityType': 'person',
            'entityId': person.id,
            'actorUid': actorUid,
            'createdAt': now,
            'before': summary(current),
            'after': summary({...current, ...fields}),
          });
        }
      });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> edit(
    String groupId,
    String actorUid,
    Person person,
    String name,
    String? notes,
  ) =>
      _update(groupId, actorUid, person, {'displayName': name, 'notes': notes});
  @override
  Future<void> setActive(
    String groupId,
    String actorUid,
    Person person,
    bool active,
  ) => _update(groupId, actorUid, person, {'isActive': active});
}
