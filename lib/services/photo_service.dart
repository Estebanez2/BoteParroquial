import 'dart:typed_data';
import '../models/photo_target.dart';

abstract interface class PhotoService {
  Future<PhotoAccess> access(String actorUid, PhotoTarget target);
  Future<Uint8List?> read(String actorUid, PhotoTarget target);
  Future<void> upload(String actorUid, PhotoTarget target, Uint8List image);
  Future<void> remove(String actorUid, PhotoTarget target);
}

class PhotoReadResult {
  const PhotoReadResult({this.bytes, this.version, this.notModified = false});
  final Uint8List? bytes;
  final String? version;
  final bool notModified;
}

abstract interface class VersionedPhotoService implements PhotoService {
  Future<PhotoReadResult> readVersion(
    String actorUid,
    PhotoTarget target,
    String? version,
  );
}

abstract interface class PhotoPickerService {
  Future<Uint8List?> pick(PhotoSource source, {bool darkTheme = true});
  Future<Uint8List?> edit(Uint8List bytes, {bool darkTheme = true});
}
