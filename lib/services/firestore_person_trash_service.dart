import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_failure.dart';
import '../models/person.dart';
import '../models/trashed_person.dart';
import 'firestore_person_service.dart';
import 'person_trash_service.dart';
import 'supabase_connection_service.dart';

class FirestorePersonTrashService implements PersonTrashService {
  const FirestorePersonTrashService(this._db, this._photos);
  final FirebaseFirestore _db;
  final SupabaseConnectionService _photos;
  static const _ineligible = AppFailure(
    FailureCode.invalidData,
    'Solo se pueden enviar a la papelera personas sin historial ni cuenta vinculada. Las personas antiguas sin protección de historial deben inactivarse.',
  );
  static const _conflict = AppFailure(
    FailureCode.invalidData,
    'La persona ha cambiado o ha vencido el plazo de restauración. Actualiza el listado.',
  );
  static AppFailure _failure(FirebaseException e) => AppFailure(
    e.code == 'permission-denied'
        ? FailureCode.permissionDenied
        : FailureCode.network,
    e.code == 'permission-denied'
        ? 'No se permite esta operación. Comprueba el historial, los permisos y el plazo de diez días.'
        : 'No se pudo confirmar el cambio. Comprueba la conexión y actualiza la papelera.',
  );
  @override
  Stream<List<TrashedPerson>> watch(String groupId) async* {
    try {
      yield* _db
          .collection('groups/$groupId/persons')
          .snapshots()
          .map(
            (snapshot) => List<TrashedPerson>.unmodifiable([
              for (final doc in snapshot.docs)
                if (!doc.metadata.hasPendingWrites &&
                    doc.data()['trashedAt'] is Timestamp)
                  TrashedPerson(
                    person: FirestorePersonService.parse(groupId, doc),
                    trashedAt: (doc.data()['trashedAt'] as Timestamp)
                        .toDate()
                        .toUtc(),
                    expiresAt: (doc.data()['trashedAt'] as Timestamp)
                        .toDate()
                        .toUtc()
                        .add(const Duration(days: 10)),
                  ),
            ]),
          );
    } on FirebaseException catch (e) {
      throw _failure(e);
    }
  }

  Future<void> _change(
    String groupId,
    String uid,
    Person person,
    String operation,
  ) async {
    if (person.groupId != groupId) throw _ineligible;
    try {
      final reference = _db.doc('groups/$groupId/persons/${person.id}');
      final audit = _db.doc(
        'groups/$groupId/auditEvents/${operation == 'purged' ? 'person-purged-${person.id}' : _db.collection('unused').doc().id}',
      );
      await _db.runTransaction((tx) async {
        final data = (await tx.get(reference)).data();
        if (data == null ||
            data['updatedAt'] != Timestamp.fromDate(person.updatedAt)) {
          throw _conflict;
        }
        if (data['historyGuardVersion'] != 1 ||
            data['linkedUid'] != null ||
            data['lastParticipationPeriodId'] != null ||
            data['firstMovementId'] != null) {
          throw _ineligible;
        }
        final now = FieldValue.serverTimestamp();
        final before = {
          'displayName': data['displayName'],
          'notes': data['notes'],
          'isActive': data['isActive'],
        };
        Map<String, Object?>? after;
        if (operation == 'trashed') {
          if (data['trashedAt'] != null) throw _conflict;
          after = {...before, 'isActive': false};
          tx.update(reference, {
            'isActive': false,
            'trashedAt': now,
            'trashedBy': uid,
            'trashedWasActive': data['isActive'],
            'updatedBy': uid,
            'updatedAt': now,
            'lastAuditEventId': audit.id,
          });
        } else if (operation == 'restored') {
          if (data['trashedAt'] == null) throw _conflict;
          after = {...before, 'isActive': data['trashedWasActive']};
          tx.update(reference, {
            'isActive': data['trashedWasActive'],
            'trashedAt': FieldValue.delete(),
            'trashedBy': FieldValue.delete(),
            'trashedWasActive': FieldValue.delete(),
            'updatedBy': uid,
            'updatedAt': now,
            'lastAuditEventId': audit.id,
          });
        } else {
          if (data['trashedAt'] == null) throw _conflict;
          tx.delete(reference);
        }
        tx.set(audit, {
          'action': 'person.$operation',
          'entityType': 'person',
          'entityId': person.id,
          'actorUid': uid,
          'createdAt': now,
          'before': before,
          'after': after,
        });
      });
    } on FirebaseException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<void> trash(String groupId, String actorUid, Person person) =>
      _change(groupId, actorUid, person, 'trashed');
  @override
  Future<void> restore(String groupId, String actorUid, TrashedPerson person) =>
      _change(groupId, actorUid, person.person, 'restored');
  @override
  Future<void> purge(
    String groupId,
    String actorUid,
    TrashedPerson person,
  ) async {
    try {
      final reference = _db.doc('groups/$groupId/persons/${person.person.id}');
      await _db.runTransaction((tx) async {
        final data = (await tx.get(reference)).data();
        if (data == null ||
            data['updatedAt'] != Timestamp.fromDate(person.person.updatedAt)) {
          throw _conflict;
        }
        if (data['purgingAt'] == null) {
          tx.update(reference, {'purgingAt': FieldValue.serverTimestamp()});
        }
      });
      final response = await _photos.client.functions.invoke(
        'lifecycle-cleanup',
        body: {
          'action': 'person',
          'groupId': groupId,
          'personId': person.person.id,
        },
      );
      if (response.data is! Map || response.data['complete'] != true) {
        throw const AppFailure(
          FailureCode.network,
          'No se confirmó la limpieza de la foto; la ficha permanece en la papelera.',
        );
      }
      await _change(groupId, actorUid, person.person, 'purged');
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure(
        FailureCode.network,
        'No se confirmó la limpieza de la foto. Reintenta desde la papelera.',
      );
    }
  }
}
