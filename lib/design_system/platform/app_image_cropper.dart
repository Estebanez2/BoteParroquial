import 'package:image_cropper/image_cropper.dart';
import '../theme/app_colors.dart';

/// Native image editor behind the application's visual API.
abstract final class AppImageCropper {
  static Future<String?> edit(
    String path, {
    required bool darkTheme,
    bool panoramic = false,
  }) async {
    final colors = darkTheme ? AppColors.dark : AppColors.light;
    final result = await ImageCropper().cropImage(
      sourcePath: path,
      maxWidth: 1024,
      maxHeight: panoramic ? 576 : 1024,
      aspectRatio: CropAspectRatio(
        ratioX: panoramic ? 16 : 1,
        ratioY: panoramic ? 9 : 1,
      ),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Ajustar foto',
          toolbarColor: colors.surface,
          toolbarWidgetColor: colors.textPrimary,
          backgroundColor: colors.background,
          activeControlsWidgetColor: colors.primary,
          cropFrameColor: colors.outline,
          cropGridColor: colors.divider,
          statusBarLight: !darkTheme,
          navBarLight: !darkTheme,
          lockAspectRatio: true,
          cropStyle: panoramic ? CropStyle.rectangle : CropStyle.circle,
          showCropGrid: panoramic,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Ajustar foto',
          doneButtonTitle: 'Usar foto',
          cancelButtonTitle: 'Cancelar',
          aspectRatioLockEnabled: true,
          aspectRatioLockDimensionSwapEnabled: false,
          resetAspectRatioEnabled: false,
          rotateButtonsHidden: false,
          rotateClockwiseButtonHidden: false,
          cropStyle: panoramic ? CropStyle.rectangle : CropStyle.circle,
        ),
      ],
    );
    return result?.path;
  }
}
