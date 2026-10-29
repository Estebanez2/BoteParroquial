import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';
import '../models/user_profile.dart';
import 'profile_editor_service.dart';

class FirestoreProfileEditorService implements ProfileEditorService {
  const FirestoreProfileEditorService(this._db);
  final FirebaseFirestore _db;
  @override
  Future<void> rename(UserProfile original, String name) async {
    try {
      final target = _db.doc(FirestorePaths.user(original.uid));
      final audit = target.collection('auditEvents').doc();
      await _db.runTransaction((tx) async {
        final before = (await tx.get(target)).data();
        if (before == null ||
            before['updatedAt'] != Timestamp.fromDate(original.updatedAt)) {
          throw const AppFailure(
            FailureCode.invalidData,
            'Tu perfil ha cambiado. Vuelve a abrirlo antes de guardar.',
          );
        }
        if (before['displayName'] == name) return;
        tx.update(target, {
          'displayName': name,
          'updatedAt': FieldValue.serverTimestamp(),
          'lastAuditEventId': audit.id,
        });
        tx.set(audit, {
          'action': 'profile.renamed',
          'entityType': 'profile',
          'entityId': original.uid,
          'actorUid': original.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'before': {'displayName': before['displayName']},
          'after': {'displayName': name},
        });
      });
    } on FirebaseException catch (error) {
      throw AppFailure(
        error.code == 'unavailable'
            ? FailureCode.network
            : FailureCode.permissionDenied,
        error.code == 'unavailable'
            ? 'Necesitas conexión para cambiar tu nombre.'
            : 'No se pudo actualizar tu perfil. Comprueba tu sesión y reintenta.',
      );
    }
  }
}
