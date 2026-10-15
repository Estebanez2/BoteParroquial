import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';
import '../models/auth_user.dart';
import '../models/user_profile.dart';
import 'user_profile_service.dart';

class FirestoreUserProfileService implements UserProfileService {
  const FirestoreUserProfileService(this._firestore);
  final FirebaseFirestore _firestore;

  @override
  Future<UserProfile> ensureProfile(AuthUser user) async {
    final reference = _firestore.doc(FirestorePaths.user(user.uid));
    try {
      // Preserve createdAt when two devices open the same account concurrently.
      await _firestore.runTransaction((transaction) async {
        final existing = await transaction.get(reference);
        final fields = <String, Object?>{
          'displayName': user.displayName ?? user.email ?? 'Usuario',
          'email': user.email,
          'photoUrl': user.photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
          'lastSignInAt': FieldValue.serverTimestamp(),
        };
        if (existing.exists) {
          transaction.update(reference, fields);
        } else {
          transaction.set(reference, {
            ...fields,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });
      final document = await reference.get(
        const GetOptions(source: Source.server),
      );
      final data = document.data();
      if (data == null ||
          data['displayName'] is! String ||
          data['createdAt'] is! Timestamp ||
          data['updatedAt'] is! Timestamp ||
          (data['email'] != null && data['email'] is! String) ||
          (data['photoUrl'] != null && data['photoUrl'] is! String) ||
          (data['lastSignInAt'] != null &&
              data['lastSignInAt'] is! Timestamp)) {
        throw const AppFailure(
          FailureCode.invalidData,
          'El perfil guardado no tiene un formato válido.',
        );
      }
      return UserProfile(
        uid: document.id,
        displayName: data['displayName'] as String,
        email: data['email'] as String?,
        photoUrl: data['photoUrl'] as String?,
        createdAt: (data['createdAt'] as Timestamp).toDate().toUtc(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate().toUtc(),
        lastSignInAt: (data['lastSignInAt'] as Timestamp?)?.toDate().toUtc(),
      );
    } on FirebaseException catch (error) {
      throw switch (error.code) {
        'permission-denied' || 'unauthenticated' => const AppFailure(
          FailureCode.permissionDenied,
          'No se pudo acceder a tu perfil. Comprueba los permisos de la aplicación.',
        ),
        'unavailable' || 'deadline-exceeded' => const AppFailure(
          FailureCode.network,
          'No se pudo conectar para guardar tu perfil. Comprueba la red e inténtalo de nuevo.',
        ),
        _ => const AppFailure(
          FailureCode.unknown,
          'No se pudo guardar tu perfil. Inténtalo de nuevo.',
        ),
      };
    }
  }
}
