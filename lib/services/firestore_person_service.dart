import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';
import '../models/person.dart';
import 'person_service.dart';

class FirestorePersonService implements PersonService {
  const FirestorePersonService(this._firestore);
  final FirebaseFirestore _firestore;
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
  static Person _parse(
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
        (data['notes'] != null && data['notes'] is! String)) {
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
                .map((doc) => _parse(groupId, doc))
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
    String? notes,
  ) async {
    try {
      await _firestore.collection(FirestorePaths.persons(groupId)).doc().set({
        'displayName': name,
        'notes': notes,
        'isActive': true,
        'createdBy': actorUid,
        'updatedBy': actorUid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
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
            current['updatedAt'] != Timestamp.fromDate(person.updatedAt)) {
          throw const AppFailure(
            FailureCode.invalidData,
            'Esta persona ha cambiado desde que la abriste. Cierra el panel y vuelve a abrirla para ver los datos actuales.',
          );
        }
        transaction.update(reference, {
          ...fields,
          'updatedBy': actorUid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
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
