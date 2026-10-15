import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firestore/firestore_paths.dart';

final groupFirestoreReferencesProvider = Provider<GroupFirestoreReferences>((
  ref,
) {
  return GroupFirestoreReferences(ref.watch(firestoreProvider));
});

/// References only. Does not create documents or assign permissions.
class GroupFirestoreReferences {
  const GroupFirestoreReferences(this._firestore);
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> group(String groupId) =>
      _firestore.doc(FirestorePaths.group(groupId));
  CollectionReference<Map<String, dynamic>> members(String groupId) =>
      _firestore.collection(FirestorePaths.members(groupId));
  CollectionReference<Map<String, dynamic>> persons(String groupId) =>
      _firestore.collection(FirestorePaths.persons(groupId));
  CollectionReference<Map<String, dynamic>> movements(String groupId) =>
      _firestore.collection(FirestorePaths.movements(groupId));
}
