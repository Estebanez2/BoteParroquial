import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../design_system/lab/motion_lab_screen.dart';
import '../../../models/group_member.dart';
import '../../../models/photo_target.dart';
import '../../photos/presentation/photo_view.dart';
import '../../photos/presentation/photo_editor_screen.dart';
import '../../auth/providers/auth_providers.dart';
import '../../groups/providers/group_providers.dart';
import '../../groups/presentation/group_widgets.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import 'pending_lifecycle_panel.dart';

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
      floatingAction: AppFloatingActions<String>(
        label: 'Añadir',
        items: const {
          'create': 'Crear un nuevo grupo',
          'join': 'Entrar con código',
        },
        icons: const {'join': Icons.key_rounded},
        onSelected: (action) =>
            context.push(action == 'create' ? '/groups/new' : '/join'),
      ),
      appBar: AppTopBar(
        title: 'BoteParroquial',
        editorial: true,
        actions: [
          AppIconButton(
            icon: Icons.palette_outlined,
            label: 'Ajustes de apariencia',
            variant: AppIconButtonVariant.ghost,
            onPressed: () => context.push('/settings/appearance'),
          ),
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
              onProfile: () => context.push('/profile'),
              onCopies: () => context.push('/offline'),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (action.hasError) Text(failureMessage(action.error!)),
          const PendingLifecyclePanel(),
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
          if (motionLabEnabled) ...[
            const SizedBox(height: AppSpacing.md),
            AppNavigationTile(
              label: 'Laboratorio de animaciones',
              description:
                  'Temporal · Compara pantallas, botones y barra inferior.',
              icon: Icons.science_outlined,
              tone: AppTone.tertiary,
              onTap: () => context.push(motionLabPath),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text('Tus grupos', style: type.displayLarge),
          const SizedBox(height: AppSpacing.md),
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
        loading: () => const AppSkeleton(
          layout: AppSkeletonLayout.groups,
          label: 'Buscando tus espacios…',
        ),
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
                    'Crea tu primer grupo o entra con un código de invitación. Tus espacios aparecerán aquí.',
              )
            : Column(
                children: [
                  for (var i = 0; i < memberships.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppReveal(
                        key: ValueKey(memberships[i].groupId),
                        order: i + 1,
                        child: _GroupTile(membership: memberships[i]),
                      ),
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
          loading: () => const AppSkeleton(
            layout: AppSkeletonLayout.group,
            label: 'Abriendo espacio…',
          ),
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
                Row(
                  children: [
                    Expanded(child: Text(group.name, style: t.headingSmall)),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.of(context).textMuted,
                      size: AppSpacing.icon,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppBadge(
                      roleLabel(membership.role),
                      tone: membership.role == GroupRole.member
                          ? AppTone.neutral
                          : AppTone.info,
                      icon: membership.role == GroupRole.owner
                          ? Icons.workspace_premium_outlined
                          : Icons.people_outline,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ref
                    .watch(dashboardProvider(groupId))
                    .when(
                      skipLoadingOnReload: false,
                      skipLoadingOnRefresh: false,
                      loading: () => const AppShimmer(
                        label: 'Actualizando saldo',
                        child: AppSkeletonBlock(
                          width: AppSpacing.coverLarge,
                          height: AppSpacing.xxl,
                        ),
                      ),
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
              ],
            );
            return AppGroupEntry(
              onOpen: (origin) => context.go(
                '/groups/${Uri.encodeComponent(groupId)}',
                extra: origin,
              ),
              builder: (context, activate) => AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                variant: AppCardVariant.interactive,
                tapEffect: AppTapEffect.none,
                onTap: activate,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PhotoCover(
                      groupId: groupId,
                      name: group.name,
                      panoramic: true,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: details,
                    ),
                  ],
                ),
              ),
            );
          },
        );
  }
}
