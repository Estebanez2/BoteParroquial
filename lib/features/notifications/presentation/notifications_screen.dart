import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/group_notification.dart';
import '../../groups/presentation/group_access_body.dart';
import '../providers/notification_providers.dart';
import 'push_device_panel.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    maxWidth: AppSpacing.readingMax,
    appBar: AppTopBar(
      title: 'Tus avisos',
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver al grupo',
        onPressed: () => context.go('/groups/$groupId'),
      ),
    ),
    child: GroupAccessBody(
      groupId: groupId,
      builder: (group, member) => _Inbox(groupId: groupId),
    ),
  );
}

class _Inbox extends ConsumerWidget {
  const _Inbox({required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.watch(notificationActionProvider(groupId));
    final controller = ref.read(notificationActionProvider(groupId).notifier);
    final type = AppTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Lo que merece tu atención', style: type.displayLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tus 50 avisos más recientes de este grupo. Los recordatorios te llevarán al estado actualizado de las cuotas.',
          style: type.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Recordatorios de este grupo', style: type.headingSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Avisos a las 10:00 de la zona del grupo, 7 días y 1 día antes de acabar el mes. Desactivar el push conserva los avisos de esta bandeja.',
                style: type.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              ref
                  .watch(quotaPushEnabledProvider(groupId))
                  .when(
                    loading: () => const LoadingIndicator(
                      label: 'Consultando tu preferencia…',
                    ),
                    error: (e, _) => Text(failureMessage(e)),
                    data: (enabled) => AppChoiceBar<bool>(
                      options: const {
                        true: 'Recibir push',
                        false: 'Solo bandeja',
                      },
                      value: enabled,
                      enabled: !action.isLoading,
                      onChanged: controller.preference,
                    ),
                  ),
            ],
          ),
        ),
        for (final category in ActivityNotificationCategory.values) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  category == ActivityNotificationCategory.economic
                      ? 'Movimientos y cambios de cuota'
                      : 'Miembros, accesos e invitaciones',
                  style: type.headingSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Los avisos permanecen en la bandeja aunque desactives el push.',
                  style: type.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                ref
                    .watch(activityPushEnabledProvider((groupId, category)))
                    .when(
                      loading: () => const LoadingIndicator(
                        label: 'Consultando preferencias…',
                      ),
                      error: (e, _) => Text(failureMessage(e)),
                      data: (enabled) => AppChoiceBar<bool>(
                        key: ValueKey(category),
                        options: const {
                          true: 'Activados',
                          false: 'Desactivados',
                        },
                        value: enabled,
                        enabled: !action.isLoading,
                        onChanged: (value) =>
                            controller.activityPreference(category, value),
                      ),
                    ),
              ],
            ),
          ),
        ],
        if (action.hasError) ...[
          const SizedBox(height: AppSpacing.md),
          Text(failureMessage(action.error!)),
        ],
        const SizedBox(height: AppSpacing.lg),
        const PushDevicePanel(),
        const SizedBox(height: AppSpacing.xl),
        ref
            .watch(notificationsProvider(groupId))
            .when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () =>
                  const LoadingIndicator(label: 'Abriendo tu bandeja…'),
              error: (error, _) => EmptyState(
                icon: Icons.notifications_off_outlined,
                title: 'No pudimos abrir tus avisos',
                description: failureMessage(error),
                actionLabel: 'Reintentar',
                onAction: () => ref.invalidate(notificationsProvider(groupId)),
              ),
              data: (items) => items.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'Todavía no hay avisos',
                      description: 'Todavía no tienes avisos en este grupo.',
                    )
                  : Column(
                      children: [
                        for (final item in items)
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
                                    AppBadge(
                                      item.readAt == null
                                          ? 'Sin leer'
                                          : 'Leído',
                                      tone: item.readAt == null
                                          ? AppTone.primary
                                          : AppTone.neutral,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(item.title, style: type.headingSmall),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(item.body, style: type.bodyMedium),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      MaterialLocalizations.of(
                                        context,
                                      ).formatMediumDate(
                                        item.createdAt.toLocal(),
                                      ),
                                      style: type.bodySmall,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    if (item.readAt == null)
                                      AppButton(
                                        label: 'Marcar como leído',
                                        variant: AppButtonVariant.ghost,
                                        onPressed: action.isLoading
                                            ? null
                                            : () =>
                                                  controller.markRead(item.id),
                                      ),
                                    AppButton(
                                      label: 'Abrir en el grupo',
                                      variant: AppButtonVariant.outline,
                                      leadingIcon:
                                          Icons.calendar_month_outlined,
                                      onPressed: () => context.push(
                                        '/groups/$groupId/${_destination(item.kind)}',
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
      ],
    );
  }

  String _destination(GroupNotificationKind kind) => switch (kind) {
    GroupNotificationKind.joinRequested ||
    GroupNotificationKind.invitationRegenerated => 'invitations',
    GroupNotificationKind.quotaReminder ||
    GroupNotificationKind.unlinkedQuotaSummary ||
    GroupNotificationKind.quotaChanged => 'reports',
    GroupNotificationKind.incomeAssociated ||
    GroupNotificationKind.withdrawalAssociated ||
    GroupNotificationKind.movementCancelled => 'movements',
    _ => 'members',
  };
}
