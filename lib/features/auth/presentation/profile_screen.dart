import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/photo_target.dart';
import '../../../models/user_profile.dart';
import '../../photos/presentation/photo_view.dart';
import '../../photos/presentation/photo_editor_screen.dart';
import '../providers/auth_providers.dart';
import '../providers/profile_editor_providers.dart';
import '../../notifications/presentation/push_device_panel.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _guard = GlobalKey<AppFormGuardState>();
  @override
  Widget build(BuildContext context) => AppScaffold(
    maxWidth: AppSpacing.readingMax,
    appBar: AppTopBar(
      title: 'Tu perfil',
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver a mis grupos',
        onPressed: () => _guard.currentState == null
            ? context.go('/')
            : _guard.currentState!.requestExit(() => context.go('/')),
      ),
    ),
    child: ref
        .watch(userProfileProvider)
        .when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => const LoadingIndicator(label: 'Preparando tu perfil…'),
          error: (error, _) => EmptyState(
            icon: Icons.person_off_outlined,
            title: 'Perfil no disponible',
            description: failureMessage(error),
            actionLabel: 'Reintentar',
            onAction: () => ref.invalidate(userProfileProvider),
          ),
          data: (profile) => profile == null
              ? const SizedBox.shrink()
              : _ProfileForm(
                  key: ValueKey(profile.uid),
                  profile: profile,
                  guard: _guard,
                ),
        ),
  );
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({super.key, required this.profile, required this.guard});
  final GlobalKey<AppFormGuardState> guard;
  final UserProfile profile;
  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late final _name = TextEditingController(text: widget.profile.displayName);
  late final _original = widget.profile;
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(profileEditorProvider),
        controller = ref.read(profileEditorProvider.notifier);
    return AppFormGuard(
      key: widget.guard,
      busy: action.isLoading,
      changes: _name,
      isDirty: () => _name.text != _original.displayName,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppNavigationTile(
              label: 'Ajustes de apariencia',
              description: 'Paletas y modo claro u oscuro',
              icon: Icons.palette_outlined,
              onTap: () => context.push('/settings/appearance'),
            ),
            const SizedBox(height: AppSpacing.section),
            AppReveal(
              child: Text(
                'Así te presentas.',
                style: AppTypography.of(context).displayLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Align(
              alignment: Alignment.centerLeft,
              child: PhotoView(
                target: PhotoTarget.account(_original.uid),
                builder: (context, image, loading) => AppAvatar(
                  name: _original.displayName,
                  size: AppAvatarSize.editor,
                  image: image,
                  loading: loading,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Cambiar mi foto',
              variant: AppButtonVariant.ghost,
              leadingIcon: Icons.photo_camera_outlined,
              onPressed: () => showPhotoEditor(
                context,
                target: PhotoTarget.account(_original.uid),
                name: _original.displayName,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _original.email ?? 'Cuenta Google',
                    style: AppTypography.of(context).bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'Tu nombre en la aplicación',
                    controller: _name,
                    validator: controller.validateName,
                    enabled: !action.isLoading,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Este cambio no modifica tu cuenta Google ni los nombres independientes de personas y miembros ya guardados en tus grupos.',
                    style: AppTypography.of(context).bodySmall,
                  ),
                ],
              ),
            ),
            if (action.hasError)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(failureMessage(action.error!)),
              ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Guardar mi nombre',
              validate: () => _form.currentState?.validate() ?? false,
              leadingIcon: Icons.check_rounded,
              loading: action.isLoading,
              onPressed: () async {
                if (!_form.currentState!.validate()) return;
                if (await controller.save(_original, _name.text) &&
                    context.mounted) {
                  widget.guard.currentState?.saved();
                  context.go('/');
                  AppSnackbar.show(
                    context,
                    'Tu nombre se ha actualizado.',
                    variant: AppSnackbarVariant.success,
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            const PushDevicePanel(),
            const SizedBox(height: AppSpacing.section),
            AppButton(
              label: 'Dar de baja mi cuenta',
              leadingIcon: Icons.person_remove_outlined,
              variant: AppButtonVariant.ghost,
              onPressed: () => context.push('/account/delete'),
            ),
          ],
        ),
      ),
    );
  }
}
