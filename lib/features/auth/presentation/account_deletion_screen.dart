import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../providers/auth_providers.dart';
import '../providers/account_lifecycle_providers.dart';

class AccountDeletionScreen extends ConsumerWidget {
  const AccountDeletionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = AppTypography.of(context),
        action = ref.watch(accountClosureControllerProvider);
    final email =
        ref.watch(authStateProvider).asData?.value?.email ?? 'tu cuenta actual';
    final pending =
        ref.watch(accountClosingProvider).asData?.value == true ||
        action.asData?.value == false;
    return AppScaffold(
      maxWidth: AppSpacing.readingMax,
      appBar: AppTopBar(
        title: 'Baja de cuenta',
        leading: AppIconButton(
          icon: Icons.arrow_back_rounded,
          label: 'Volver a Inicio',
          onPressed: () => context.go('/'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            pending ? 'Termina tu baja' : 'Tu cuenta, tu decisión',
            style: type.editorialTitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Text(
              'Cuenta: $email\n\nPrimero debes transferir o eliminar los grupos que te pertenecen. Después se retirarán tus accesos, los avisos en todos tus móviles, tu perfil y tus fotos de cuenta y miembro. Las personas internas, sus fotos independientes y el historial económico de otros grupos se conservarán.',
              style: type.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            pending
                ? 'La cuenta está bloqueada para nuevas operaciones. Espera al menos treinta segundos desde la confirmación y reanuda la limpieza. Si se cierra la app, podrás continuar desde Inicio al volver a entrar con esta cuenta.'
                : 'Esta acción elimina el acceso de esta cuenta Firebase; no elimina tu cuenta de Google. Volver a entrar después creará una cuenta nueva sin recuperar automáticamente accesos o vínculos.',
            style: type.bodySmall,
          ),
          if (action.hasError)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: Text(
                failureMessage(action.error!),
                style: type.bodyMedium,
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: pending
                ? 'Verificar Google y reanudar baja'
                : 'Verificar Google y darme de baja',
            leadingIcon: Icons.person_remove_outlined,
            loading: action.isLoading,
            onPressed: () async {
              final accepted = await AppDialog.show(
                context,
                title: pending ? '¿Continuar la baja?' : '¿Eliminar tu cuenta?',
                description:
                    'Se verificará la misma cuenta de Google. Se conservará la historia económica de los grupos.',
                confirmLabel: pending ? 'Continuar' : 'Confirmar baja',
              );
              if (!accepted || !context.mounted) return;
              final done = await ref
                  .read(accountClosureControllerProvider.notifier)
                  .close();
              if (!context.mounted || done == null) return;
              if (done) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
