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
                  ? () async {
                      await controller.refresh();
                      if (!context.mounted) return;
                      final result = ref.read(pushDeviceControllerProvider);
                      AppSnackbar.show(
                        context,
                        result.hasError
                            ? failureMessage(result.error!)
                            : result.asData?.value == true
                            ? 'Registro comprobado: este móvil puede recibir avisos de tu cuenta.'
                            : 'Este móvil no está registrado. Activa los avisos para recibirlos.',
                        variant: result.hasError
                            ? AppSnackbarVariant.error
                            : result.asData?.value == true
                            ? AppSnackbarVariant.success
                            : AppSnackbarVariant.info,
                      );
                    }
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
              'Comprobar registro verifica y actualiza la vinculación de este móvil; no envía un aviso de prueba. Retirar avisos los desactiva aquí para todos los grupos de esta cuenta, sin borrar la bandeja ni cambiar otros móviles. Cada categoría del grupo tiene además su propio interruptor. Al cerrar sesión confirmamos la retirada de este móvil antes de salir; necesitarás conexión. Solo se registra la cuenta activa, aunque un aviso enviado antes de salir podría llegar con retraso.',
              style: type.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
