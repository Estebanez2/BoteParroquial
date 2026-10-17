import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image;
import 'package:image_picker/image_picker.dart';
import '../core/errors/app_failure.dart';
import '../models/photo_target.dart';
import 'photo_service.dart';
import '../design_system/platform/app_image_cropper.dart';

/// Decode/resize away from the UI isolate; encode a new JPEG without EXIF/GPS.
Uint8List preparePhoto(Uint8List input) {
  final decoded = image.decodeImage(input);
  if (decoded == null || decoded.width * decoded.height > 24000000) {
    throw const AppFailure(
      FailureCode.invalidData,
      'No se puede preparar esta imagen. Elige otra foto.',
    );
  }
  final oriented = image.bakeOrientation(decoded);
  final resized = image.copyResize(
    oriented,
    width: oriented.width >= oriented.height ? 1024 : null,
    height: oriented.height > oriented.width ? 1024 : null,
    maintainAspect: true,
  );
  // Copy only pixels, not source metadata or additional frames.
  final clean = image.Image(width: resized.width, height: resized.height);
  image.compositeImage(clean, resized);
  for (final quality in [85, 70, 55]) {
    final bytes = image.encodeJpg(clean, quality: quality);
    if (bytes.length <= 524288) return bytes;
  }
  throw const AppFailure(
    FailureCode.invalidData,
    'La imagen es demasiado grande. Elige otra foto.',
  );
}

class DevicePhotoPickerService implements PhotoPickerService {
  DevicePhotoPickerService(this._picker);
  final ImagePicker _picker;

  @override
  Future<Uint8List?> edit(Uint8List bytes, {bool darkTheme = true}) async {
    final root = await getTemporaryDirectory();
    final directory = await Directory(
      '${root.path}/bote_photo_edit_',
    ).createTemp();
    try {
      final source = File('${directory.path}/current.jpg');
      await source.writeAsBytes(bytes, flush: true);
      final cropped = await AppImageCropper.edit(
        source.path,
        darkTheme: darkTheme,
      );
      return cropped == null ? null : await _prepare(XFile(cropped));
    } on PlatformException {
      throw const AppFailure(
        FailureCode.invalidData,
        'No se pudo abrir el editor para esta foto. Inténtalo de nuevo.',
      );
    } on FileSystemException {
      throw const AppFailure(
        FailureCode.configuration,
        'No se pudo preparar la foto en este móvil. Inténtalo de nuevo.',
      );
    } finally {
      // Only remove the generated private input, never a gallery source file.
      try {
        await directory.delete(recursive: true);
      } catch (_) {}
    }
  }

  Future<Uint8List> _prepare(XFile file) async {
    if (await file.length() > 20 * 1024 * 1024) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Elige una foto de menos de 20 MB.',
      );
    }
    try {
      return await compute(preparePhoto, await file.readAsBytes());
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure(
        FailureCode.invalidData,
        'No se pudo preparar esta imagen. Elige otra foto.',
      );
    }
  }

  @override
  Future<Uint8List?> pick(PhotoSource source, {bool darkTheme = true}) async {
    try {
      // A picker result left by a terminated process has no trusted account or
      // target context. Discard it; never attach it to the next signed-in user.
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _picker.retrieveLostData();
      }
      final file = await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
        requestFullMetadata: false,
      );
      if (file == null) return null;
      final cropped = await AppImageCropper.edit(
        file.path,
        darkTheme: darkTheme,
      );
      return cropped == null ? null : _prepare(XFile(cropped));
    } on PlatformException {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'No se pudo abrir la cámara o la galería. Revisa los permisos de BoteParroquial en los ajustes del móvil.',
      );
    }
  }
}
