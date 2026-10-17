import 'dart:typed_data';
import 'dart:convert';
import '../core/errors/app_failure.dart';
import '../models/photo_target.dart';
import '../services/photo_service.dart';
import '../services/photo_cache_service.dart';

class PhotoRepository {
  PhotoRepository(this._photos, this._picker, {PhotoCacheService? cache})
    : cache = cache ?? PhotoCacheService();
  final PhotoService _photos;
  final PhotoPickerService _picker;
  final PhotoCacheService cache;
  final _requests = <String, Future<CachedPhoto>>{};

  void _validate(String actorUid, PhotoTarget target) {
    bool valid(String value) =>
        value.isNotEmpty &&
        value.length <= 128 &&
        value != '.' &&
        value != '..' &&
        !RegExp(r'[/\\\x00-\x1f\x7f]').hasMatch(value);
    if (!valid(actorUid) ||
        !valid(target.id) ||
        (target.groupId != null && !valid(target.groupId!))) {
      throw const AppFailure(
        FailureCode.invalidData,
        'El destino de la foto no es válido.',
      );
    }
    if (target.kind == PhotoKind.account && target.id != actorUid) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'Solo puedes cambiar tu foto de cuenta.',
      );
    }
  }

  Future<PhotoAccess> access(String uid, PhotoTarget target) {
    _validate(uid, target);
    return _photos.access(uid, target);
  }

  Future<Uint8List?> read(String uid, PhotoTarget target) =>
      watch(uid, target).last;

  Stream<Uint8List?> watch(String uid, PhotoTarget target) async* {
    _validate(uid, target);
    final expected = cache.epoch(uid, target);
    final cached = cache.peek(uid, target) ?? await cache.load(uid, target);
    if (expected != cache.epoch(uid, target)) return;
    if (cached != null) {
      yield cached.bytes;
      if (cached.isFresh) return;
    }
    final key = jsonEncode([
      uid,
      target.kind.name,
      target.groupId,
      target.id,
      expected,
    ]);
    try {
      final request = _requests.putIfAbsent(key, () async {
        final service = _photos;
        final result = service is VersionedPhotoService
            ? await service.readVersion(uid, target, cached?.version)
            : PhotoReadResult(bytes: await service.read(uid, target));
        final entry = CachedPhoto(
          result.notModified ? cached?.bytes : result.bytes,
          result.version ?? (result.notModified ? cached?.version : null),
          DateTime.now(),
        );
        await cache.put(uid, target, entry, expected);
        return entry;
      });
      final result = await request;
      if (identical(_requests[key], request)) _requests.remove(key);
      if (expected != cache.epoch(uid, target)) return;
      if (cached == null || !identical(cached.bytes, result.bytes)) {
        yield result.bytes;
      }
    } catch (error) {
      _requests.remove(key);
      if (expected != cache.epoch(uid, target)) return;
      if (error is AppFailure && error.code == FailureCode.permissionDenied) {
        await cache.remove(uid, target);
        rethrow;
      }
      if (cached == null) rethrow;
      // Temporary connectivity errors retain the already-authorized local image.
    }
  }

  Future<Uint8List?> pick(PhotoSource source, {bool darkTheme = true}) =>
      _picker.pick(source, darkTheme: darkTheme);

  Future<Uint8List?> editCurrent(
    String uid,
    PhotoTarget target, {
    Uint8List? draft,
    bool darkTheme = true,
  }) async {
    _validate(uid, target);
    if (!(await _photos.access(uid, target)).canEdit) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'Ya no puedes editar esta foto.',
      );
    }
    final bytes =
        draft ?? cache.peek(uid, target)?.bytes ?? await read(uid, target);
    if (bytes == null) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Todavía no hay una foto que editar.',
      );
    }
    return _picker.edit(bytes, darkTheme: darkTheme);
  }

  Future<void> upload(String uid, PhotoTarget target, Uint8List bytes) async {
    _validate(uid, target);
    if (bytes.isEmpty || bytes.length > 524288) {
      throw const AppFailure(
        FailureCode.invalidData,
        'La foto supera el tamaño permitido.',
      );
    }
    if (!(await _photos.access(uid, target)).canEdit) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'Ya no puedes cambiar esta foto.',
      );
    }
    cache.beginChange(uid, target);
    final expected = cache.epoch(uid, target);
    await _photos.upload(uid, target, bytes);
    await cache.put(
      uid,
      target,
      CachedPhoto(bytes.asUnmodifiableView(), null, DateTime.now()),
      expected,
    );
  }

  Future<void> remove(String uid, PhotoTarget target) async {
    _validate(uid, target);
    if (!(await _photos.access(uid, target)).canEdit) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'Ya no puedes cambiar esta foto.',
      );
    }
    await _photos.remove(uid, target);
    await cache.remove(uid, target);
  }
}
