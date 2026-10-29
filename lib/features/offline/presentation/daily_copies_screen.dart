import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../providers/daily_snapshot_providers.dart';

class DailyCopiesScreen extends ConsumerWidget {
  const DailyCopiesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyCopyControllerProvider),
        type = AppTypography.of(context);
    return AppScaffold(
      appBar: AppTopBar(
        title: 'Copias en este móvil',
        leading: AppIconButton(
          icon: Icons.arrow_back_rounded,
          label: 'Volver',
          onPressed: () => context.go('/'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tu información, también sin red', style: type.editorialTitle),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Se guarda una copia diaria al abrir con conexión, por Wi-Fi o datos móviles. Conservamos las siete últimas copias diarias completas de esta cuenta. Las fotos dependen de la caché; no se descargan todas. No se generan copias con la app cerrada.',
            style: type.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Comprobar copia de hoy',
            leadingIcon: Icons.cloud_download_outlined,
            loading: state.busy,
            onPressed: () =>
                ref.read(dailyCopyControllerProvider.notifier).refresh(),
          ),
          if (state.error != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Text(
                'No se completó la comprobación o descarga. Las copias anteriores se conservan. ${failureMessage(state.error!)}',
                style: type.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (state.entries.isEmpty && !state.busy)
            const EmptyState(
              icon: Icons.save_outlined,
              title: 'Aún no hay copias completas',
              description:
                  'Abre la app con conexión, esta cuenta y al menos un grupo para preparar la primera. La caché normal sigue siendo independiente.',
            ),
          for (final entry in state.entries) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    MaterialLocalizations.of(
                      context,
                    ).formatFullDate(entry.asOf.toLocal()),
                    style: type.headingSmall,
                  ),
                  Text(
                    '${TimeOfDay.fromDateTime(entry.asOf.toLocal()).format(context)} · ${entry.groups} grupos · ${entry.documents} documentos',
                    style: type.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Ver copia guardada',
                    variant: AppButtonVariant.outline,
                    onPressed: () => context.push('/offline/${entry.day}'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            'Una copia puede ser más antigua que la caché. Al abrirla verás siempre su fecha y solo podrás consultar. No restaura ni modifica Firebase.',
            style: type.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (state.entries.isNotEmpty || state.error != null)
            AppButton(
              label: 'Eliminar las copias de esta cuenta en este móvil',
              variant: AppButtonVariant.ghost,
              onPressed: state.busy
                  ? null
                  : () async {
                      final accepted = await AppDialog.show(
                        context,
                        title: '¿Eliminar las copias locales?',
                        description:
                            'No elimina datos del servidor ni de otros móviles. Necesitarás conexión para crear una copia nueva.',
                        confirmLabel: 'Eliminar copias',
                      );
                      if (accepted) {
                        await ref
                            .read(dailyCopyControllerProvider.notifier)
                            .clear();
                      }
                    },
            ),
        ],
      ),
    );
  }
}

class DailyCopyEntryButton extends ConsumerWidget {
  const DailyCopyEntryButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyCopyControllerProvider);
    return AppButton(
      label: state.entries.isEmpty
          ? 'Copias para consultar sin conexión'
          : 'Ver copias guardadas en este móvil',
      variant: AppButtonVariant.outline,
      leadingIcon: Icons.offline_pin_outlined,
      onPressed: () => context.push('/offline'),
    );
  }
}
