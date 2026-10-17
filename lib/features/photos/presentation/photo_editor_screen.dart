import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/photo_target.dart';
import '../providers/photo_providers.dart';

Future<void> showPhotoEditor(
  BuildContext context, {
  required PhotoTarget target,
  required String name,
}) => Navigator.of(context).push<void>(
  PageRouteBuilder<void>(
    transitionDuration: AppMotion.duration(context, AppMotion.durationNormal),
    reverseTransitionDuration: AppMotion.duration(
      context,
      AppMotion.durationNormal,
    ),
    pageBuilder: (context, animation, secondaryAnimation) =>
        PhotoEditorScreen(target: target, name: name),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  ),
);

class PhotoEditorScreen extends ConsumerWidget {
  const PhotoEditorScreen({
    super.key,
    required this.target,
    required this.name,
  });
  final PhotoTarget target;
  final String name;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(photoControllerProvider(target));
    final access = ref.watch(photoAccessProvider(target));
    final photo = ref.watch(photoProvider(target));
    final presentation = ref.watch(photoPresentationProvider(target));
    final allowed =
        !access.isLoading &&
        !access.hasError &&
        access.asData?.value.canEdit == true;
    final bytes = state.draft ?? presentation.bytes;
    final image = bytes == null ? null : MemoryImage(bytes);
    final controller = ref.read(photoControllerProvider(target).notifier);
    void refresh() {
      ref.read(photoRefreshProvider)(target);
    }

    return PopScope(
      canPop: !state.busy,
      child: AppScaffold(
        maxWidth: AppSpacing.readingMax,
        appBar: AppTopBar(
          title: 'La imagen de tu comunidad',
          leading: AppIconButton(
            icon: Icons.arrow_back_rounded,
            label: 'Volver',
            onPressed: state.busy ? null : () => Navigator.pop(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeroPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTypography.of(context).editorialTitle),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    target.kind == PhotoKind.account
                        ? 'Esta es tu foto de cuenta. También se verá en tus grupos cuando no tengan una foto específica para ti.'
                        : 'Una imagen para reconocernos. Solo las personas con acceso al grupo pueden verla.',
                    style: AppTypography.of(context).bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: target.kind == PhotoKind.group
                  ? AppCover(
                      name: name,
                      image: image,
                      large: true,
                      loading: presentation.loading,
                    )
                  : AppAvatar(
                      name: name,
                      image: image,
                      size: AppAvatarSize.editor,
                      loading: presentation.loading,
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (access.isLoading)
              const LoadingIndicator(label: 'Comprobando permisos…'),
            if (access.hasError || photo.hasError)
              EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'No pudimos actualizar la foto',
                description: failureMessage(access.error ?? photo.error!),
                actionLabel: 'Actualizar foto',
                onAction: state.busy ? null : refresh,
              ),
            if (!access.isLoading && !access.hasError && !allowed)
              Text(
                'Puedes consultar la foto si tienes acceso. Su edición está reservada a la persona autorizada.',
                style: AppTypography.of(context).bodyMedium,
              ),
            if (allowed) ...[
              if (bytes != null) ...[
                AppButton(
                  label: 'Editar foto actual',
                  leadingIcon: Icons.crop_rotate_outlined,
                  variant: AppButtonVariant.outline,
                  fullWidth: true,
                  onPressed: state.busy
                      ? null
                      : () => controller.editCurrent(
                          darkTheme:
                              Theme.of(context).brightness == Brightness.dark,
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppAdaptiveRow(
                children: [
                  AppButton(
                    label: 'Elegir de la galería',
                    leadingIcon: Icons.photo_library_outlined,
                    onPressed: state.busy
                        ? null
                        : () => controller.select(
                            PhotoSource.gallery,
                            darkTheme:
                                Theme.of(context).brightness == Brightness.dark,
                          ),
                  ),
                  AppButton(
                    label: 'Hacer una foto',
                    leadingIcon: Icons.camera_alt_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: state.busy
                        ? null
                        : () => controller.select(
                            PhotoSource.camera,
                            darkTheme:
                                Theme.of(context).brightness == Brightness.dark,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (state.draft != null) ...[
                Text(
                  'Vista previa: se compartirá cuando pulses Guardar foto.',
                  style: AppTypography.of(context).bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Guardar foto',
                  leadingIcon: Icons.save_outlined,
                  fullWidth: true,
                  loading: state.busy,
                  onPressed: state.busy
                      ? null
                      : () async {
                          final saved = await controller.save();
                          if (context.mounted && saved) {
                            AppSnackbar.show(
                              context,
                              'Foto guardada.',
                              variant: AppSnackbarVariant.success,
                            );
                          }
                        },
                ),
              ],
              if (!photo.isLoading &&
                  !photo.hasError &&
                  photo.asData?.value != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: target.kind == PhotoKind.member
                      ? 'Usar foto de cuenta'
                      : 'Quitar foto',
                  variant: AppButtonVariant.ghost,
                  onPressed: state.busy
                      ? null
                      : () async {
                          final confirmed = await AppDialog.show(
                            context,
                            title: target.kind == PhotoKind.member
                                ? '¿Volver a la foto de cuenta?'
                                : '¿Quitar esta foto?',
                            description: target.kind == PhotoKind.member
                                ? 'Se quitará solo la foto de este grupo. Se usará tu foto de cuenta si existe.'
                                : 'Volverán a mostrarse las iniciales. Se conservan todos los demás datos.',
                            confirmLabel: 'Quitar foto',
                            variant: AppDialogVariant.confirmation,
                          );
                          if (!context.mounted || !confirmed) return;
                          final saved = await controller.save(remove: true);
                          if (context.mounted && saved) {
                            AppSnackbar.show(
                              context,
                              'Foto retirada.',
                              variant: AppSnackbarVariant.success,
                            );
                          }
                        },
                ),
              ],
            ],
            if (state.busy && state.draft == null)
              const LoadingIndicator(label: 'Preparando la foto…'),
            if (state.error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                state.error!,
                style: AppTypography.of(
                  context,
                ).bodyMedium.copyWith(color: AppColors.of(context).danger),
              ),
              AppButton(
                label: 'Comprobar foto guardada',
                variant: AppButtonVariant.ghost,
                onPressed: state.busy ? null : refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
