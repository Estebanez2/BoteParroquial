import '../core/errors/app_failure.dart';
import '../models/user_profile.dart';
import '../services/profile_editor_service.dart';

class ProfileEditorRepository {
  const ProfileEditorRepository(this._service);
  final ProfileEditorService _service;
  static String? nameError(String? name) => name == null || name.trim().isEmpty
      ? 'Escribe tu nombre.'
      : name.trim().length > 256
      ? 'El nombre admite hasta 256 caracteres.'
      : null;
  Future<void> rename(String uid, UserProfile original, String name) {
    if (original.uid != uid) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'Solo puedes editar tu propio perfil.',
      );
    }
    final error = nameError(name);
    if (error != null) throw AppFailure(FailureCode.invalidData, error);
    return _service.rename(original, name.trim());
  }
}
