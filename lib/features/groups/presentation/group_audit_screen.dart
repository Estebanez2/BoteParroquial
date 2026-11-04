import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/audit_labels.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/audit_history.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/audit_history_providers.dart';
import '../providers/group_management_providers.dart';
import 'audit_event_detail.dart';
import 'audit_history_controls.dart';
import 'group_access_body.dart';

class GroupAuditScreen extends ConsumerWidget {
  const GroupAuditScreen({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    maxWidth: AppSpacing.readingMax,
    appBar: AppTopBar(
      title: 'Historial administrativo',
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver al grupo',
        onPressed: () => context.go('/groups/$groupId'),
      ),
    ),
    child: GroupAccessBody(
      groupId: groupId,
      builder: (group, member) {
        if (!ref.watch(canEditGroupProvider(groupId))) {
          return const EmptyState(
            icon: Icons.lock_outline,
            title: 'Solo gestión autorizada',
            description:
                'Este historial está reservado a propietarios y administradores autorizados.',
          );
        }
        final history = ref.watch(auditHistoryProvider(groupId));
        final events = ref.watch(filteredAuditProvider(groupId));
        final actors = ref.watch(auditActorsProvider(groupId));
        final actions = ref.read(auditHistoryProvider(groupId).notifier);
        final t = AppTypography.of(context), colors = AppColors.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppReveal(
              child: AppHeroPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'La memoria de tu comunidad',
                      style: t.editorialTitle.copyWith(color: colors.onHero),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      history.events.isNotEmpty || history.serverConfirmed
                          ? '${history.events.length} cambios cargados'
                          : history.error != null
                          ? 'Historial no disponible'
                          : 'Consultando cambios…',
                      style: t.headingSmall.copyWith(color: colors.onHero),
                    ),
                    Text(
                      'Identidad, accesos, cuotas y repartos. Cada registro conserva quién cambió qué. Los movimientos tienen su historial económico separado.',
                      style: t.bodyMedium.copyWith(color: colors.onHero),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AuditHistoryControls(key: ValueKey(groupId), groupId: groupId),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: history.hasNewChanges
                  ? 'Mostrar cambios nuevos'
                  : 'Actualizar historial',
              leadingIcon: Icons.refresh_rounded,
              variant: AppButtonVariant.outline,
              onPressed: history.loading || history.loadingMore
                  ? null
                  : actions.refresh,
            ),
            AppDelayedVisibility(
              visible: !history.serverConfirmed && history.events.isNotEmpty,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  'Datos guardados aún sin confirmar. La conexión se comprobará antes de consultar cambios antiguos.',
                  style: t.bodySmall,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (history.loading)
              const LoadingIndicator(label: 'Cargando cambios…'),
            if (history.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'No pudimos cargar los cambios',
                  description: failureMessage(history.error!),
                  actionLabel: 'Reintentar consulta',
                  onAction:
                      history.nextCursor != null && history.serverConfirmed
                      ? actions.loadMore
                      : actions.refresh,
                ),
              ),
            if (!history.loading &&
                history.error == null &&
                !history.serverConfirmed &&
                history.events.isEmpty)
              const LoadingIndicator(label: 'Confirmando el historial…'),
            if (!history.loading &&
                history.error == null &&
                history.serverConfirmed &&
                history.events.isEmpty)
              const EmptyState(
                icon: Icons.history_rounded,
                title: 'Aquí empieza la trazabilidad',
                description:
                    'No hay cambios administrativos registrados en esta consulta. Los cambios anteriores al registro no se reconstruyen.',
              ),
            if (history.events.isNotEmpty)
              Text(
                '${events.length} coincidencias entre ${history.events.length} cambios cargados. La búsqueda no consulta automáticamente el resto del historial.',
                style: t.bodySmall,
              ),
            if (history.events.isNotEmpty && events.isEmpty)
              const EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Sin coincidencias entre los cambios cargados',
                description:
                    'Limpia los filtros o consulta más cambios antiguos.',
              ),
            for (final event in events)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: _EventCard(
                  event: event,
                  actor: actors[event.actorUid] ?? 'Usuario no disponible',
                  onDetails: () {
                    final uid = ref.read(authStateProvider).asData?.value?.uid;
                    if (uid == null) return;
                    AppBottomSheet.show<void>(
                      context,
                      title: 'Detalle del cambio',
                      builder: (_) => AuditEventDetail(
                        groupId: groupId,
                        eventId: event.id,
                        currency: group.currency,
                        expectedUid: uid,
                      ),
                    );
                  },
                ),
              ),
            if (history.nextCursor != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Cargar más cambios',
                leadingIcon: Icons.expand_more_rounded,
                loading: history.loadingMore,
                onPressed: history.canLoadMore ? actions.loadMore : null,
              ),
            ] else if (history.serverConfirmed &&
                history.events.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Has llegado al final de esta consulta.',
                style: t.bodySmall,
              ),
            ],
          ],
        );
      },
    ),
  );
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.actor,
    required this.onDetails,
  });
  final GroupAuditEvent event;
  final String actor;
  final VoidCallback onDetails;
  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context),
        locale = MaterialLocalizations.of(context);
    final date = event.createdAt.toLocal();
    return AppReveal(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppBadge(auditEntityLabels[event.entityType] ?? 'Otros cambios'),
            const SizedBox(height: AppSpacing.md),
            Text(
              auditActionLabels[event.action] ?? 'Cambio administrativo',
              style: t.headingSmall,
            ),
            Text(actor, style: t.bodyMedium),
            Text(
              '${locale.formatMediumDate(date)} · ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(date), alwaysUse24HourFormat: true)} · Hora de este móvil',
              style: t.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Ver detalle',
              variant: AppButtonVariant.ghost,
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: onDetails,
            ),
          ],
        ),
      ),
    );
  }
}
