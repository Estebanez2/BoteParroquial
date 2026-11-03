import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/person.dart';
import '../../../models/photo_target.dart';
import '../../photos/presentation/photo_view.dart';
import '../providers/person_providers.dart';
import '../providers/person_trash_providers.dart';
import 'person_editor.dart';
import '../../quotas/presentation/participation_editor.dart';
import '../../quotas/presentation/first_month_setup.dart';

class PersonsSection extends ConsumerWidget {
  const PersonsSection({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref.watch(canManagePersonsProvider(groupId));
    final type = AppTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Personas', style: type.displayLarge),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Personas que forman parte del bote, tengan o no una cuenta en la app.',
          style: type.bodyMedium,
        ),
        if (canManage) ...[
          const SizedBox(height: AppSpacing.xl),
          FirstMonthSetupPanel(groupId: groupId),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Añadir persona',
              fullWidth: true,
              leadingIcon: Icons.add_rounded,
              onPressed: () => showPersonEditor(context, ref, groupId),
            ),
          ),
          AppButton(
            label: 'Abrir papelera',
            leadingIcon: Icons.delete_outline,
            variant: AppButtonVariant.ghost,
            onPressed: () => context.push('/groups/$groupId/trash'),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        ref
            .watch(personsProvider(groupId))
            .when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () => const AppSkeleton(
                layout: AppSkeletonLayout.people,
                label: 'Cargando personas…',
              ),
              error: (error, _) => EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'No pudimos cargar las personas',
                description: failureMessage(error),
                actionLabel: 'Reintentar personas',
                onAction: () => ref.invalidate(personsProvider(groupId)),
              ),
              data: (persons) => persons.isEmpty
                  ? const EmptyState(
                      icon: Icons.people_outline,
                      title: 'El primer nombre lo cambia todo.',
                      description: 'Todavía no hay personas en este bote.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final person in persons)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.lg,
                            ),
                            child: AppReveal(
                              key: ValueKey(person.id),
                              child: _PersonCard(
                                groupId: groupId,
                                person: person,
                                canManage: canManage,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
      ],
    );
  }
}

class _PersonCard extends ConsumerWidget {
  const _PersonCard({
    required this.groupId,
    required this.person,
    required this.canManage,
  });
  final String groupId;
  final Person person;
  final bool canManage;
  Future<void> _changeState(BuildContext context, WidgetRef ref) async {
    if (!person.isActive || person.lastParticipationPeriodId != null) {
      await showParticipationEditor(
        context,
        ref,
        person,
        starting: !person.isActive,
      );
      return;
    }
    final confirmed = await AppDialog.show(
      context,
      title: person.isActive
          ? '¿Inactivar a ${person.displayName}?'
          : '¿Activar a ${person.displayName}?',
      description: person.isActive
          ? 'Conservará todos sus datos y podrás reactivarla cuando quieras. Si tiene un administrador vinculado, pasará a ser miembro. Reactivarla no recuperará ese rol.'
          : 'Volverá a aparecer como persona activa del bote.',
      confirmLabel: person.isActive ? 'Inactivar persona' : 'Activar persona',
    );
    if (!context.mounted || !confirmed) return;
    final saved = await ref
        .read(personControllerProvider(groupId).notifier)
        .setActive(person, !person.isActive);
    if (!context.mounted) return;
    final result = ref.read(personControllerProvider(groupId));
    AppSnackbar.show(
      context,
      saved
          ? 'Estado de la persona actualizado.'
          : failureMessage(
              result.error ??
                  const AppFailure(
                    FailureCode.unknown,
                    'No se pudo guardar el cambio.',
                  ),
            ),
      variant: saved ? AppSnackbarVariant.success : AppSnackbarVariant.error,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.watch(personControllerProvider(groupId));
    final t = AppTypography.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhotoAvatar(
                target: PhotoTarget.person(groupId, person.id),
                name: person.displayName,
                size: AppAvatarSize.large,
                interactive: true,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(person.displayName, style: t.labelLarge),
                    if (person.notes != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        person.notes!,
                        style: t.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    AppBadge(
                      person.isActive ? 'Activa' : 'Inactiva',
                      tone: person.isActive ? AppTone.success : AppTone.neutral,
                    ),
                  ],
                ),
              ),
              if (canManage) ...[
                const SizedBox(width: AppSpacing.sm),
                Column(
                  children: [
                    AppIconButton(
                      icon: Icons.edit_outlined,
                      label: 'Editar',
                      onPressed: action.isLoading
                          ? null
                          : () => showPersonEditor(
                              context,
                              ref,
                              groupId,
                              person: person,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppActionMenu<String>(
                      label: 'Más opciones',
                      enabled: !action.isLoading,
                      items: {
                        'state': person.isActive ? 'Inactivar' : 'Activar',
                        'trash': 'Enviar a la papelera',
                      },
                      onSelected: (value) async {
                        if (value == 'state') {
                          await _changeState(context, ref);
                          return;
                        }
                        final confirmed = await AppDialog.show(
                          context,
                          title: '¿Enviar a la papelera?',
                          description:
                              'Solo se permite sin movimientos, repartos, periodos de cuota ni cuenta vinculada. Podrás restaurarla durante diez días. Si tiene historial, usa Inactivar.',
                          confirmLabel: 'Enviar a la papelera',
                        );
                        if (!confirmed || !context.mounted) return;
                        final ok = await ref
                            .read(
                              personTrashControllerProvider(groupId).notifier,
                            )
                            .trash(person);
                        if (!context.mounted) return;
                        AppSnackbar.show(
                          context,
                          ok
                              ? 'Persona enviada a la papelera.'
                              : failureMessage(
                                  ref
                                          .read(
                                            personTrashControllerProvider(
                                              groupId,
                                            ),
                                          )
                                          .error ??
                                      const AppFailure(
                                        FailureCode.cancelled,
                                        'La operación no se ha completado; actualiza el listado.',
                                      ),
                                ),
                          variant: ok
                              ? AppSnackbarVariant.success
                              : AppSnackbarVariant.error,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
          const Divider(height: AppSpacing.xl),
          AppButton(
            label: 'Ver ficha y aportaciones',
            leadingIcon: Icons.insights_outlined,
            variant: AppButtonVariant.ghost,
            onPressed: () =>
                context.push('/groups/$groupId/persons/${person.id}'),
          ),
          Text(
            'Persona creada el ${MaterialLocalizations.of(context).formatMediumDate(person.createdAt.toLocal())}',
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }
}
