import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../providers/notification_providers.dart';

class PushDevicePanel extends ConsumerWidget {
  const PushDevicePanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pushDeviceControllerProvider);
    final controller = ref.read(pushDeviceControllerProvider.notifier);
    final registered = state.asData?.value == true;
    final type = AppTypography.of(context);
    return AppReveal(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Los avisos, a tu manera', style: type.editorialTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(
              registered
                  ? 'Este móvil está registrado para tu cuenta.'
                  : 'Al entrar por primera vez te pedimos permiso para los avisos. Aquí puedes activarlos de nuevo; en la pantalla bloqueada no mostramos importes.',
              style: type.bodyMedium,
            ),
            if (state.hasError) ...[
              const SizedBox(height: AppSpacing.md),
              Text(failureMessage(state.error!), style: type.bodySmall),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: registered
                  ? 'Comprobar registro'
                  : 'Activar avisos en este móvil',
              leadingIcon: Icons.notifications_active_outlined,
              loading: state.isLoading,
              onPressed: state.isLoading
                  ? null
                  : registered
                  ? controller.refresh
                  : controller.enable,
            ),
            if (registered || state.hasError) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Retirar avisos de este móvil',
                variant: AppButtonVariant.ghost,
                onPressed: state.isLoading ? null : controller.disable,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              'La preferencia de cada grupo se cambia en su bandeja. Para cerrar sesión confirmaremos antes la retirada de este móvil; necesitarás conexión si lo has registrado.',
              style: type.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
