import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../design_system/design_system.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(firebaseStartupProvider);
    final action = ref.watch(authControllerProvider);
    final session = ref.watch(authStateProvider);
    final t = AppTypography.of(context);
    return AppScaffold(
      background: const AppLogoBackdrop(),
      maxWidth: AppSpacing.readingMax,
      appBar: const AppTopBar(
        title: 'BoteParroquial',
        leading: AppBrand(compact: true),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          AppReveal(
            child: const AppWelcomePanel(
              title: 'Tu comunidad.\nTodo, en su sitio.',
              description:
                  'Personas, aportaciones y proyectos en un espacio que cuidáis juntos.',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tu próximo encuentro empieza aquí',
                  style: t.headingSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Accede con tu cuenta de Google para entrar en tus grupos.',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                if (!startup.isReady) ...[
                  Text(
                    startup.error == null
                        ? 'Configuración de Firebase pendiente.'
                        : 'Firebase no disponible. Completa la configuración o revisa la conexión.',
                    style: t.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (action.hasError) ...[
                  Text(
                    failureMessage(action.error!),
                    semanticsLabel:
                        'Error de acceso: ${failureMessage(action.error!)}',
                    style: t.bodyMedium.copyWith(
                      color: AppColors.of(context).danger,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (session.hasError) ...[
                  Text(failureMessage(session.error!), style: t.bodyMedium),
                  AppButton(
                    label: 'Reintentar sesión',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => ref
                        .read(authControllerProvider.notifier)
                        .retrySession(),
                  ),
                ],
                AppButton(
                  label: action.isLoading
                      ? 'Conectando…'
                      : 'Continuar con Google',
                  leadingIcon: Icons.login_rounded,
                  fullWidth: true,
                  loading: action.isLoading,
                  onPressed: !startup.isReady || action.isLoading
                      ? null
                      : () =>
                            ref.read(authControllerProvider.notifier).signIn(),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.of(context).primary,
                      size: AppSpacing.icon,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Sin contraseñas nuevas. Tus permisos pertenecen a cada grupo.',
                        style: t.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
