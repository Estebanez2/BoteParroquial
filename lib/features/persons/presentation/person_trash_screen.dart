import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../groups/presentation/group_access_body.dart';
import '../providers/person_providers.dart';
import '../providers/person_trash_providers.dart';

class PersonTrashScreen extends ConsumerWidget {
  const PersonTrashScreen({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    maxWidth: AppSpacing.readingMax,
    appBar: AppTopBar(
      title: 'Papelera de personas',
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver a personas',
        onPressed: () => context.go('/groups/$groupId/persons'),
      ),
    ),
    child: GroupAccessBody(
      groupId: groupId,
      builder: (_, _) {
        if (!ref.watch(canManagePersonsProvider(groupId))) {
          return const EmptyState(
            icon: Icons.lock_outline,
            title: 'Acceso reservado a gestores',
            description: 'No tienes permiso para consultar la papelera.',
          );
        }
        final type = AppTypography.of(context),
            action = ref.watch(personTrashControllerProvider(groupId));
        final controller = ref.read(
          personTrashControllerProvider(groupId).notifier,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Un margen para rectificar', style: type.editorialTitle),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Durante diez días puedes recuperar las personas enviadas aquí. El plazo se comprueba con la hora del servidor. Las personas con historial se inactivan y no pasan por esta papelera.',
              style: type.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (action.hasError)
              Text(failureMessage(action.error!), style: type.bodyMedium),
            ref
                .watch(personTrashProvider(groupId))
                .when(
                  loading: () =>
                      const LoadingIndicator(label: 'Abriendo papelera…'),
                  error: (e, _) => EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'No se pudo abrir la papelera',
                    description: failureMessage(e),
                  ),
                  data: (rows) => rows.isEmpty
                      ? const EmptyState(
                          icon: Icons.delete_outline,
                          title: 'La papelera está vacía',
                          description:
                              'No hay personas pendientes de recuperar.',
                        )
                      : Column(
                          children: [
                            for (final row in rows)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.lg,
                                ),
                                child: AppReveal(
                                  child: AppCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          row.person.displayName,
                                          style: type.headingSmall,
                                        ),
                                        Text(
                                          'Recuperable hasta ${MaterialLocalizations.of(context).formatFullDate(row.expiresAt.toLocal())}',
                                          style: type.bodySmall,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        AppButton(
                                          label: controller.canRestore(row)
                                              ? 'Restaurar persona'
                                              : 'Eliminar definitivamente',
                                          variant: AppButtonVariant.outline,
                                          loading: action.isLoading,
                                          onPressed: () async {
                                            final restore = controller
                                                .canRestore(row);
                                            final accepted = await AppDialog.show(
                                              context,
                                              title: restore
                                                  ? '¿Restaurar persona?'
                                                  : '¿Eliminar definitivamente?',
                                              description: restore
                                                  ? 'Volverá al listado con el estado que tenía antes.'
                                                  : 'Ha terminado el plazo de recuperación. Se eliminará su ficha; el evento administrativo se conservará.',
                                              confirmLabel: restore
                                                  ? 'Restaurar'
                                                  : 'Eliminar',
                                            );
                                            if (!accepted || !context.mounted) {
                                              return;
                                            }
                                            final ok = restore
                                                ? await controller.restore(row)
                                                : await controller.purge(row);
                                            if (context.mounted && ok) {
                                              AppSnackbar.show(
                                                context,
                                                restore
                                                    ? 'Persona restaurada.'
                                                    : 'Ficha eliminada.',
                                                variant:
                                                    AppSnackbarVariant.success,
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
          ],
        );
      },
    ),
  );
}
