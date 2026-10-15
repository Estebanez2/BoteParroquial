import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/group_member.dart';
import '../providers/group_providers.dart';
import 'group_access_body.dart';
import 'group_widgets.dart';

class GroupMembersScreen extends ConsumerWidget {
  const GroupMembersScreen({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    maxWidth: AppSpacing.readingMax,
    appBar: AppTopBar(
      title: 'Miembros',
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver al resumen',
        onPressed: () => context.go('/groups/$groupId'),
      ),
    ),
    child: GroupAccessBody(
      groupId: groupId,
      builder: (group, membership) => ref
          .watch(groupMembersProvider(groupId))
          .when(
            skipLoadingOnReload: false,
            skipLoadingOnRefresh: false,
            loading: () => const LoadingIndicator(label: 'Cargando miembros…'),
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
                        '${members.length}',
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
                for (final member in members)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: AppReveal(
                      child: AppCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppAvatar(
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
}
