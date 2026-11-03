import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/group.dart';
import '../../../models/group_member.dart';
import '../providers/group_providers.dart';
import 'group_sync_notice.dart';
import 'group_identity_header.dart';

class GroupAccessBody extends ConsumerWidget {
  const GroupAccessBody({
    super.key,
    required this.groupId,
    required this.builder,
    this.edgeToEdge = false,
  });
  final String groupId;
  final Widget Function(Group group, GroupMember membership) builder;
  final bool edgeToEdge;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = ref.watch(membershipsProvider);
    final member = ref.watch(currentMembershipProvider(groupId));
    if (memberships.isLoading) {
      return const AppSkeleton(
        layout: AppSkeletonLayout.group,
        label: 'Comprobando tu acceso…',
      );
    }
    if (memberships.hasError) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'No pudimos comprobar tu acceso',
        description: failureMessage(memberships.error!),
        actionLabel: 'Reintentar acceso',
        onAction: () => ref.invalidate(membershipsProvider),
      );
    }
    if (member == null) {
      return EmptyState(
        icon: Icons.lock_outline,
        title: 'Este espacio no está disponible',
        description: 'Necesitas una membresía activa para entrar.',
        actionLabel: 'Volver a mis grupos',
        onAction: () => context.go('/'),
      );
    }
    return ref
        .watch(groupProvider(groupId))
        .when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => const AppSkeleton(
            layout: AppSkeletonLayout.group,
            label: 'Preparando tu espacio…',
          ),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: edgeToEdge
                          ? const EdgeInsets.symmetric(
                              horizontal: AppSpacing.page,
                            )
                          : EdgeInsets.zero,
                      child: GroupSyncNotice(groupId: groupId),
                    ),
                    GroupIdentityHeader(
                      group: group,
                      membership: member,
                      panoramic: edgeToEdge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: edgeToEdge
                          ? const EdgeInsets.fromLTRB(
                              AppSpacing.page,
                              0,
                              AppSpacing.page,
                              AppSpacing.page,
                            )
                          : EdgeInsets.zero,
                      child: builder(group, member),
                    ),
                  ],
                ),
        );
  }
}
