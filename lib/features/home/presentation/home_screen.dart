import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/group_member.dart';
import '../../auth/providers/auth_providers.dart';
import '../../groups/providers/group_providers.dart';
import '../../groups/presentation/group_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final action = ref.watch(authControllerProvider);
    final type = AppTypography.of(context);
    return AppScaffold(
      maxWidth: AppSpacing.readingMax,
      appBar: AppTopBar(
        title: 'BoteParroquial',
        actions: [
          AppButton(
            label: 'Cerrar sesión',
            variant: AppButtonVariant.ghost,
            onPressed: action.isLoading
                ? null
                : () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (action.hasError) Text(failureMessage(action.error!)),
          profile.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () =>
                const LoadingIndicator(label: 'Preparando tu perfil…'),
            error: (error, _) => EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'No pudimos preparar tu perfil',
              description: failureMessage(error),
              actionLabel: 'Reintentar perfil',
              onAction: () =>
                  ref.read(authControllerProvider.notifier).retryProfile(),
            ),
            data: (user) => user == null
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, ${user.displayName}',
                        style: type.headingSmall,
                      ),
                      if (user.email != null)
                        Text(user.email!, style: type.bodySmall),
                      const SizedBox(height: AppSpacing.xl),
                      const GroupOpening(
                        eyebrow: 'UN LUGAR PARA LO COMPARTIDO',
                        title: 'Lo nuestro,\nen común.',
                        description:
                            'Cada grupo es un espacio propio. Elige dónde quieres estar hoy.',
                      ),
                      const SizedBox(height: AppSpacing.section),
                      Text('Tus espacios', style: type.headingMedium),
                      const SizedBox(height: AppSpacing.lg),
                      const _GroupList(),
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        'Tu perfil está guardado y tu sesión está activa.',
                        style: type.bodySmall,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _GroupList extends ConsumerWidget {
  const _GroupList();
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(membershipsProvider)
      .when(
        skipLoadingOnRefresh: false,
        skipLoadingOnReload: false,
        loading: () => const LoadingIndicator(label: 'Buscando tus espacios…'),
        error: (error, _) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Tus grupos están a un reintento',
          description: failureMessage(error),
          actionLabel: 'Reintentar grupos',
          onAction: () => ref.invalidate(membershipsProvider),
        ),
        data: (memberships) => memberships.isEmpty
            ? const EmptyState(
                icon: Icons.door_front_door_outlined,
                title: 'Tu próximo espacio empieza aquí',
                description:
                    'Todavía no tienes grupos asignados. Cuando se active tu acceso, lo encontrarás aquí.',
              )
            : Column(
                children: [
                  for (final membership in memberships)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: _GroupTile(membership: membership),
                    ),
                ],
              ),
      );
}

class _GroupTile extends ConsumerWidget {
  const _GroupTile({required this.membership});
  final GroupMember membership;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = membership.groupId;
    final type = AppTypography.of(context);
    return ref
        .watch(groupProvider(groupId))
        .when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => const LoadingIndicator(label: 'Abriendo espacio…'),
          error: (error, _) => AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(failureMessage(error)),
                AppButton(
                  label: 'Reintentar espacio',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => ref.invalidate(groupProvider(groupId)),
                ),
              ],
            ),
          ),
          data: (group) => group == null
              ? const SizedBox.shrink()
              : AppReveal(
                  child: AppCard(
                    variant: AppCardVariant.interactive,
                    onTap: () =>
                        context.go('/groups/${Uri.encodeComponent(groupId)}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppAvatar(name: group.name),
                            const Spacer(),
                            const Icon(Icons.arrow_outward_rounded),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(group.name, style: type.headingLarge),
                        const SizedBox(height: AppSpacing.md),
                        AppBadge(
                          roleLabel(membership.role),
                          tone: AppTone.primary,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Entrar a este espacio', style: type.labelLarge),
                      ],
                    ),
                  ),
                ),
        );
  }
}
