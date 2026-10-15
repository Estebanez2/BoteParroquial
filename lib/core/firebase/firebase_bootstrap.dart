import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';

class FirebaseStartup {
  const FirebaseStartup.pending() : app = null, error = null;
  const FirebaseStartup.ready(this.app) : error = null;
  const FirebaseStartup.failed(this.error) : app = null;

  final FirebaseApp? app;
  final Object? error;
  bool get isReady => app != null;
}

final firebaseStartupProvider = Provider<FirebaseStartup>(
  (ref) => const FirebaseStartup.pending(),
);

Future<FirebaseStartup> initializeFirebase() async {
  try {
    return FirebaseStartup.ready(
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
    );
  } catch (error, stackTrace) {
    // Allow the initial screen to open before Firebase is configured.
    debugPrint('Firebase initialization failed: $error\n$stackTrace');
    return FirebaseStartup.failed(error);
  }
}
