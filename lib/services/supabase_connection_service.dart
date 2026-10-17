import 'package:supabase/supabase.dart';

import '../core/errors/app_failure.dart';

/// SDK connection only. Photo operations use the authorizing Edge Function;
/// repositories and screens must not use SDK objects.
class SupabaseConnectionService {
  SupabaseConnectionService({
    required String url,
    required String publishableKey,
    required Future<String?> Function() firebaseToken,
  }) : client = SupabaseClient(
         url,
         publishableKey,
         accessToken: () async {
           final token = await firebaseToken();
           if (token == null || token.isEmpty) {
             throw const AppFailure(
               FailureCode.permissionDenied,
               'Inicia sesión para acceder a las fotos.',
             );
           }
           return token;
         },
       );

  // Infrastructure dependency for future SDK adapters, never for presentation.
  final SupabaseClient client;

  Future<void> dispose() => client.dispose();
}
