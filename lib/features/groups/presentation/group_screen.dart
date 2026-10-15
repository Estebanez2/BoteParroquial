import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../providers/group_providers.dart';
import 'group_widgets.dart';
import '../../persons/presentation/persons_section.dart';

class GroupScreen extends ConsumerWidget {
  const GroupScreen({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(currentMembershipProvider(groupId));
    final memberships = ref.watch(membershipsProvider);
    final type = AppTypography.of(context);
    return AppScaffold(
      maxWidth: AppSpacing.readingMax,
      appBar: AppTopBar(
        title: 'Tu espacio',
        leading: AppIconButton(
          icon: Icons.arrow_back_rounded,
          label: 'Volver a mis grupos',
          onPressed: () => context.go('/'),
        ),
      ),
      child: memberships.isLoading
          ? const LoadingIndicator(label: 'Comprobando tu acceso…')
          : memberships.hasError
          ? EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'No pudimos comprobar tu acceso',
              description: failureMessage(memberships.error!),
              actionLabel: 'Reintentar acceso',
              onAction: () => ref.invalidate(membershipsProvider),
            )
          : membership == null
          ? EmptyState(
              icon: Icons.lock_outline,
              title: 'Este espacio no está disponible',
              description: 'Necesitas una membresía activa para entrar.',
              actionLabel: 'Volver a mis grupos',
              onAction: () => context.go('/'),
            )
          : ref
                .watch(groupProvider(groupId))
                .when(
                  skipLoadingOnRefresh: false,
                  skipLoadingOnReload: false,
                  loading: () =>
                      const LoadingIndicator(label: 'Preparando tu espacio…'),
                  error: (error, _) => EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'No pudimos abrir el espacio',
                    description: failureMessage(error),
                    actionLabel: 'Reintentar',
                    onAction: () => ref.invalidate(groupProvider(groupId)),
                  ),
                  data: (group) => group == null
                      ? const EmptyState(
                          icon: Icons.lock_outline,
                          title: 'Espacio no disponible',
                          description: 'Este grupo ya no está activo.',
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GroupOpening(
                              eyebrow: 'TU ESPACIO COMPARTIDO',
                              title: group.name,
                              description:
                                  group.description ??
                                  'Un punto de encuentro para cuidar lo que compartís.',
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                AppBadge(
                                  roleLabel(membership.role),
                                  tone: AppTone.primary,
                                ),
                                AppBadge(group.currency),
                                AppBadge(
                                  group.timeZone,
                                  icon: Icons.public_outlined,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.section),
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cada aporte deja huella.',
                                    style: type.headingMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Consulta los ingresos, las retiradas y la historia de cada cambio.',
                                    style: type.bodyMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                  AppButton(
                                    label: 'Ver movimientos',
                                    leadingIcon: Icons.receipt_long_outlined,
                                    onPressed: () => context.push(
                                      '/groups/$groupId/movements',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.section),
                            PersonsSection(groupId: groupId),
                            const SizedBox(height: AppSpacing.section),
                            Text(
                              'Quiénes lo compartís',
                              style: type.headingMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Las cuentas que tienen acceso a este espacio son distintas de las personas del bote.',
                              style: type.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            ref
                                .watch(groupMembersProvider(groupId))
                                .when(
                                  skipLoadingOnRefresh: false,
                                  skipLoadingOnReload: false,
                                  loading: () => const LoadingIndicator(
                                    label: 'Cargando miembros…',
                                  ),
                                  error: (error, _) => EmptyState(
                                    icon: Icons.cloud_off_outlined,
                                    title: 'No pudimos cargar los miembros',
                                    description: failureMessage(error),
                                    actionLabel: 'Reintentar miembros',
                                    onAction: () => ref.invalidate(
                                      groupMembersProvider(groupId),
                                    ),
                                  ),
                                  data: (members) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      for (final member in members)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: AppSpacing.md,
                                          ),
                                          child: AppReveal(
                                            child: AppCard(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  AppAvatar(
                                                    name: member.displayName,
                                                  ),
                                                  const SizedBox(
                                                    height: AppSpacing.md,
                                                  ),
                                                  Text(
                                                    member.displayName,
                                                    style: type.headingSmall,
                                                  ),
                                                  const SizedBox(
                                                    height: AppSpacing.md,
                                                  ),
                                                  Wrap(
                                                    spacing: AppSpacing.sm,
                                                    runSpacing: AppSpacing.sm,
                                                    children: [
                                                      AppBadge(
                                                        roleLabel(member.role),
                                                      ),
                                                      AppBadge(
                                                        member.isActive
                                                            ? 'Activo'
                                                            : 'Inactivo',
                                                        tone: member.isActive
                                                            ? AppTone.success
                                                            : AppTone.neutral,
                                                      ),
                                                      if (member.uid ==
                                                          membership.uid)
                                                        const AppBadge(
                                                          'Tú',
                                                          tone: AppTone.primary,
                                                        ),
                                                    ],
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
                        ),
                ),
    );
  }
}
