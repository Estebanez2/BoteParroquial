import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/supabase_connection_service.dart';
import '../firebase/firebase_providers.dart';
import 'supabase_config.dart';

/// Lazy infrastructure wiring: no second login, persisted Supabase session or
/// startup network request. Photo repositories consume service adapters.
final supabaseConnectionProvider = Provider<SupabaseConnectionService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final connection = SupabaseConnectionService(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    // Resolve the current Firebase user/token for each request, never cache a
    // token captured at initialization. Firebase refreshes expired tokens.
    firebaseToken: () async => auth.currentUser?.getIdToken(),
  );
  ref.onDispose(() => unawaited(connection.dispose()));
  return connection;
});
