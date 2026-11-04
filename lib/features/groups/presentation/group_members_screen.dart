import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/group_member.dart';
import '../../../models/photo_target.dart';
import '../../photos/presentation/photo_view.dart';
import '../providers/group_providers.dart';
import '../providers/group_invitation_providers.dart';
import '../providers/member_link_providers.dart';
import 'group_access_body.dart';
import 'group_bottom_navigation.dart';
import 'group_widgets.dart';
import 'group_section_top_bar.dart';
import 'member_link_editor.dart';
import 'member_role_button.dart';
import '../providers/member_role_providers.dart';
import '../../../core/offline/offline_mode.dart';

class GroupMembersScreen extends ConsumerWidget {
  const GroupMembersScreen({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    maxWidth: AppSpacing.readingMax,
    bottomNavigation: GroupBottomNavigation(groupId: groupId, selectedIndex: 2),
    appBar: GroupSectionTopBar(
      groupId: groupId,
      title: 'Miembros',
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver a participantes',
        onPressed: () => context.go('/groups/$groupId/participants'),
      ),
    ),
    child: GroupAccessBody(
      groupId: groupId,
      builder: (group, membership) => ref
          .watch(groupMembersProvider(groupId))
          .when(
            skipLoadingOnReload: false,
            skipLoadingOnRefresh: false,
            loading: () => const AppSkeleton(
              layout: AppSkeletonLayout.people,
              label: 'Cargando miembros…',
            ),
            error: (error, _) => EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'No pudimos cargar los miembros',
              description: failureMessage(error),
              actionLabel: 'Reintentar miembros',
              onAction: () => ref.invalidate(groupMembersProvider(groupId)),
            ),
            data: (members) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppHeroPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MIEMBROS DEL GRUPO',
                        style: AppTypography.of(context).labelSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${members.where((member) => member.isActive).length}',
                        style: AppTypography.of(context).moneyHero,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Personas con una cuenta y acceso a este espacio. Son distintas de las personas internas del bote.',
                        style: AppTypography.of(context).bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (!ref.watch(offlineReadOnlyProvider))
                  AppButton(
                    label: 'Invitaciones y solicitudes',
                    leadingIcon: Icons.person_add_alt_outlined,
                    onPressed: () =>
                        context.push('/groups/$groupId/invitations'),
                  ),
                const SizedBox(height: AppSpacing.lg),
                if (ref.watch(invitationControllerProvider(groupId)).hasError)
                  Text(
                    failureMessage(
                      ref.watch(invitationControllerProvider(groupId)).error!,
                    ),
                  ),
                if (ref.watch(memberRoleControllerProvider(groupId)).hasError)
                  Text(
                    failureMessage(
                      ref.watch(memberRoleControllerProvider(groupId)).error!,
                    ),
                  ),
                if (ref.watch(canTransferOwnershipProvider(groupId)))
                  AppButton(
                    label: 'Transferir la propiedad',
                    variant: AppButtonVariant.outline,
                    leadingIcon: Icons.workspace_premium_outlined,
                    onPressed: () => context.push('/groups/$groupId/transfer'),
                  ),
                const SizedBox(height: AppSpacing.lg),
                AppChoiceBar<bool>(
                  options: const {false: 'Todos', true: 'Sin vínculo'},
                  value: ref.watch(memberListFilterProvider(groupId)),
                  onChanged: ref
                      .read(memberListFilterProvider(groupId).notifier)
                      .select,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (ref.watch(memberListFilterProvider(groupId)) &&
                    ref.watch(unlinkedMembersProvider(groupId)).isEmpty)
                  const EmptyState(
                    icon: Icons.link_rounded,
                    title: 'Todos tienen su vínculo',
                    description:
                        'No hay miembros activos pendientes de vincular.',
                  ),
                for (final member in ref.watch(
                  visibleGroupMembersProvider(groupId),
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: AppReveal(
                      child: AppCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PhotoAvatar(
                              target: PhotoTarget.member(groupId, member.uid),
                              interactive: true,
                              name: member.displayName,
                              size: AppAvatarSize.large,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.displayName,
                                    style: AppTypography.of(
                                      context,
                                    ).headingSmall,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: [
                                      AppBadge(
                                        roleLabel(member.role),
                                        tone: member.role == GroupRole.admin
                                            ? AppTone.info
                                            : AppTone.primary,
                                        icon: member.role == GroupRole.owner
                                            ? Icons.workspace_premium_outlined
                                            : Icons.shield_outlined,
                                      ),
                                      AppBadge(
                                        member.isActive ? 'Activo' : 'Inactivo',
                                        tone: member.isActive
                                            ? AppTone.success
                                            : AppTone.neutral,
                                      ),
                                      if (member.uid == membership.uid)
                                        const AppBadge(
                                          'Tú',
                                          tone: AppTone.info,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'En el grupo desde ${MaterialLocalizations.of(context).formatMediumDate(member.joinedAt.toLocal())}',
                                    style: AppTypography.of(context).bodySmall,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  MemberLinkButton(member: member),
                                  MemberRoleButton(member: member),
                                  if (ref.watch(
                                    canRemoveMemberProvider((groupId, member)),
                                  ))
                                    AppButton(
                                      label: member.uid == membership.uid
                                          ? 'Salir del grupo'
                                          : 'Retirar acceso',
                                      variant: AppButtonVariant.ghost,
                                      leadingIcon: Icons.logout_rounded,
                                      onPressed:
                                          ref
                                              .watch(
                                                invitationControllerProvider(
                                                  groupId,
                                                ),
                                              )
                                              .isLoading
                                          ? null
                                          : () => _remove(
                                              context,
                                              ref,
                                              member,
                                              member.uid == membership.uid,
                                            ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
    ),
  );

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    GroupMember member,
    bool own,
  ) async {
    final confirmed = await AppDialog.show(
      context,
      title: own
          ? '¿Salir de este grupo?'
          : '¿Retirar el acceso de ${member.displayName}?',
      description:
          'Perderá el acceso a este espacio. Su persona interna, sus fotos y su historial económico se conservan. Una futura entrada no recupera permisos de administrador.',
      confirmLabel: own ? 'Salir del grupo' : 'Retirar acceso',
    );
    if (!confirmed || !context.mounted) return;
    final router = GoRouter.of(context);
    final removed = await ref
        .read(invitationControllerProvider(groupId).notifier)
        .remove(member);
    if (removed && own) router.go('/');
  }
}
