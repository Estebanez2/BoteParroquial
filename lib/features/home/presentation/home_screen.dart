import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/group_member.dart';
import '../../../models/photo_target.dart';
import '../../photos/presentation/photo_view.dart';
import '../../photos/presentation/photo_editor_screen.dart';
import '../../auth/providers/auth_providers.dart';
import '../../groups/providers/group_providers.dart';
import '../../groups/presentation/group_widgets.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final action = ref.watch(authControllerProvider);
    final type = AppTypography.of(context);
    final session = ref.watch(authStateProvider);
    final user = session.isLoading || session.hasError
        ? null
        : session.asData?.value;
    final savedProfile = profile.isLoading || profile.hasError
        ? null
        : profile.asData?.value;
    final ownProfile = savedProfile?.uid == user?.uid ? savedProfile : null;
    return AppScaffold(
      maxWidth: AppSpacing.readingMax,
      appBar: AppTopBar(
        title: 'BoteParroquial',
        editorial: true,
        leading: const Icon(Icons.groups_outlined),
        actions: [
          PhotoView(
            target: PhotoTarget.account(user?.uid ?? ''),
            builder: (context, image, loading) => AppAvatarMenu(
              accountId: user?.uid,
              name: ownProfile?.displayName ?? user?.displayName ?? 'Tu cuenta',
              email: ownProfile?.email ?? user?.email,
              enabled: !action.isLoading,
              image: image,
              loading: loading,
              onPhoto: user == null
                  ? null
                  : () => showPhotoEditor(
                      context,
                      target: PhotoTarget.account(user.uid),
                      name:
                          ownProfile?.displayName ??
                          user.displayName ??
                          'Tu cuenta',
                    ),
              onSignOut: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
            ),
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
            data: (user) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.xl),
          const GroupOpening(
            eyebrow: 'JUNTOS HACEMOS MÁS',
            title: 'Gestiona el bote\nde tu parroquia.',
            description:
                'Una forma sencilla y transparente de organizar los fondos de tu comunidad para actividades y proyectos.',
          ),
          const SizedBox(height: AppSpacing.section),
          Text('Tus espacios', style: type.editorialTitle),
          const SizedBox(height: AppSpacing.lg),
          const _GroupList(),
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
    final t = AppTypography.of(context);
    return ref
        .watch(groupProvider(groupId))
        .when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => const LoadingIndicator(label: 'Abriendo espacio…'),
          error: (error, _) => AppCard(
            child: Column(
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
          data: (group) {
            if (group == null) return const SizedBox.shrink();
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name, style: t.editorialTitle),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppBadge(
                      roleLabel(membership.role),
                      tone: AppTone.primary,
                      icon: membership.role == GroupRole.owner
                          ? Icons.workspace_premium_outlined
                          : Icons.people_outline,
                    ),
                    AppBadge(group.currency),
                  ],
                ),
                if (group.description?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(group.description!, style: t.bodySmall),
                ],
                const SizedBox(height: AppSpacing.md),
                ref
                    .watch(dashboardProvider(groupId))
                    .when(
                      skipLoadingOnReload: false,
                      skipLoadingOnRefresh: false,
                      loading: () =>
                          Text('Actualizando saldo…', style: t.bodySmall),
                      error: (error, _) =>
                          Text('Saldo no disponible', style: t.bodySmall),
                      data: (summary) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saldo disponible', style: t.bodySmall),
                          MoneyText(
                            summary.balanceCents,
                            currency: group.currency,
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Entrar',
                  trailingIcon: Icons.chevron_right_rounded,
                  size: AppButtonSize.compact,
                  onPressed: () =>
                      context.go('/groups/${Uri.encodeComponent(groupId)}'),
                ),
              ],
            );
            return AppReveal(
              child: AppCard(
                variant: AppCardVariant.interactive,
                onTap: () =>
                    context.go('/groups/${Uri.encodeComponent(groupId)}'),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PhotoCover(groupId: groupId, name: group.name),
                          const SizedBox(height: AppSpacing.lg),
                          details,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PhotoCover(groupId: groupId, name: group.name),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(child: details),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
  }
}
