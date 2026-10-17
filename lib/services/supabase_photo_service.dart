import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase/supabase.dart';
import '../core/errors/app_failure.dart';
import '../models/photo_target.dart';
import 'photo_service.dart';
import 'supabase_connection_service.dart';

class SupabasePhotoService implements VersionedPhotoService {
  SupabasePhotoService(this._connection);
  final SupabaseConnectionService _connection;

  Map<String, Object> _target(PhotoTarget target) => {
    'kind': target.kind.name,
    if (target.groupId != null) 'groupId': target.groupId!,
    if (target.kind == PhotoKind.account || target.kind == PhotoKind.member)
      'uid': target.id,
    if (target.kind == PhotoKind.person) 'personId': target.id,
  };

  Future<Object?> _call(
    String action,
    String actorUid,
    PhotoTarget target, [
    Uint8List? image,
    String? version,
  ]) async {
    try {
      final response = await _connection.client.functions.invoke(
        'photo-access',
        body: {
          'action': action,
          'actorUid': actorUid,
          'target': _target(target),
          if (image != null) 'imageBase64': base64Encode(image),
          'ifNoneMatch': ?version,
        },
      );
      return response.data;
    } on FunctionException catch (error) {
      if ((action == 'read' || action == 'readCached') && error.status == 404) {
        return null;
      }
      throw AppFailure(
        error.status == 401 || error.status == 403
            ? FailureCode.permissionDenied
            : FailureCode.network,
        switch (error.status) {
          401 =>
            'Tu sesión no está disponible. Vuelve a entrar para gestionar fotos.',
          403 => 'Ya no tienes permiso para acceder o cambiar esta foto.',
          413 => 'La imagen supera el tamaño permitido.',
          415 => 'Selecciona una imagen JPEG, PNG o WebP.',
          _ =>
            'No pudimos confirmar la operación. Comprueba la conexión y actualiza la foto antes de reintentar.',
        },
      );
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure(
        FailureCode.network,
        'No pudimos confirmar la operación. Comprueba la conexión y actualiza la foto antes de reintentar.',
      );
    }
  }

  @override
  Future<PhotoAccess> access(String actorUid, PhotoTarget target) async {
    final data = await _call('access', actorUid, target);
    if (data is! Map) {
      throw const AppFailure(
        FailureCode.unknown,
        'No pudimos comprobar los permisos de la foto.',
      );
    }
    return PhotoAccess(
      canRead: data['canRead'] == true,
      canEdit: data['canEdit'] == true,
    );
  }

  @override
  Future<Uint8List?> read(String actorUid, PhotoTarget target) async {
    final data = await _call('read', actorUid, target);
    if (data == null) return null;
    if (data is Uint8List) return data;
    throw const AppFailure(FailureCode.unknown, 'No pudimos cargar la imagen.');
  }

  @override
  Future<PhotoReadResult> readVersion(
    String actorUid,
    PhotoTarget target,
    String? version,
  ) async {
    final data = await _call('readCached', actorUid, target, null, version);
    if (data == null) return const PhotoReadResult();
    if (data is! Map || data['version'] is! String) {
      throw const AppFailure(
        FailureCode.unknown,
        'No pudimos actualizar la foto.',
      );
    }
    return PhotoReadResult(
      notModified: data['notModified'] == true,
      version: data['version'] as String,
      bytes: data['notModified'] == true
          ? null
          : base64Decode(data['imageBase64'] as String).asUnmodifiableView(),
    );
  }

  @override
  Future<void> upload(
    String actorUid,
    PhotoTarget target,
    Uint8List image,
  ) async {
    await _call('upload', actorUid, target, image);
  }

  @override
  Future<void> remove(String actorUid, PhotoTarget target) async {
    await _call('remove', actorUid, target);
  }
}
