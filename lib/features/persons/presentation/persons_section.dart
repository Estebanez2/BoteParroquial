import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/person.dart';
import '../providers/person_providers.dart';
import 'person_editor.dart';

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
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Añadir persona',
              fullWidth: true,
              leadingIcon: Icons.add_rounded,
              onPressed: () => showPersonEditor(context, ref, groupId),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        ref
            .watch(personsProvider(groupId))
            .when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () =>
                  const LoadingIndicator(label: 'Cargando personas…'),
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
    final confirmed = await AppDialog.show(
      context,
      title: person.isActive
          ? '¿Inactivar a ${person.displayName}?'
          : '¿Activar a ${person.displayName}?',
      description: person.isActive
          ? 'Conservará todos sus datos y podrás reactivarla cuando quieras.'
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
              AppAvatar(name: person.displayName, size: AppAvatarSize.large),
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
                    AppActionMenu<bool>(
                      label: 'Más opciones',
                      enabled: !action.isLoading,
                      items: {true: person.isActive ? 'Inactivar' : 'Activar'},
                      onSelected: (_) => _changeState(context, ref),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const Divider(height: AppSpacing.xl),
          Text(
            'Persona creada el ${MaterialLocalizations.of(context).formatMediumDate(person.createdAt.toLocal())}',
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }
}
