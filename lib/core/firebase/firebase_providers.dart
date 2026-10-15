import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_bootstrap.dart';

final firebaseAppProvider = Provider<FirebaseApp>((ref) {
  final app = ref.watch(firebaseStartupProvider).app;
  if (app == null) {
    throw StateError('Firebase no está configurado o no pudo inicializarse.');
  }
  return app;
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instanceFor(app: ref.watch(firebaseAppProvider));
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instanceFor(app: ref.watch(firebaseAppProvider));
});
