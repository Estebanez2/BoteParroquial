import 'package:flutter/material.dart';
import '../../../models/photo_target.dart';
import '../../photos/presentation/photo_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/dashboard_summary.dart';
import '../../../models/group.dart';
import '../../../models/group_member.dart';
import '../../../models/movement.dart';
import '../../groups/presentation/group_access_body.dart';
import '../../groups/presentation/group_bottom_navigation.dart';
import '../../groups/providers/group_management_providers.dart';

import '../../movements/providers/movement_providers.dart';
import '../../movements/presentation/pending_movement_card.dart';
import '../../persons/providers/person_providers.dart';
import '../providers/dashboard_providers.dart';
import '../../reports/presentation/quota_report_section.dart';
import 'balance_trend_panel.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context) => AppScaffold(
    maxWidth: AppSpacing.readingMax,
    padding: EdgeInsets.zero,
    bottomNavigation: GroupBottomNavigation(groupId: groupId, selectedIndex: 0),
    appBar: AppTopBar(
      title: 'BoteParroquial',
      actions: [
        AppIconButton(
          icon: Icons.notifications_none_rounded,
          label: 'Abrir mis avisos',
          onPressed: () => context.push('/groups/$groupId/notifications'),
        ),
      ],
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver a mis grupos',
        onPressed: () => context.go('/'),
      ),
    ),
    child: GroupAccessBody(
      groupId: groupId,
      edgeToEdge: true,
      showIdentity: true,
      builder: (group, membership) =>
          _Dashboard(group: group, membership: membership),
    ),
  );
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.group, required this.membership});
  final Group group;
  final GroupMember membership;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = group.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PendingMovementCard(groupId: groupId, currency: group.currency),
        ref
            .watch(dashboardProvider(groupId))
            .when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () => const AppSkeleton(
                layout: AppSkeletonLayout.summary,
                label: 'Actualizando el resumen…',
              ),
              error: (error, _) => EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'No pudimos preparar el resumen',
                description: failureMessage(error),
                actionLabel: 'Reintentar resumen',
                onAction: () {
                  ref.invalidate(movementsProvider(groupId));
                  ref.invalidate(dashboardCashProvider(groupId));
                  ref.invalidate(dashboardRecentProvider(groupId));
                  ref.invalidate(personsProvider(groupId));
                },
              ),
              data: (summary) => _SummaryBody(group: group, summary: summary),
            ),
      ],
    );
  }
}

class _SummaryBody extends ConsumerWidget {
  const _SummaryBody({required this.group, required this.summary});
  final Group group;
  final DashboardSummary summary;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = AppTypography.of(context);
    final groupId = group.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppReveal(
          order: 1,
          child: BalanceCard(
            balanceCents: summary.balanceCents,
            currency: group.currency,
            caption: summary.cashConfirmedAt == null
                ? null
                : 'Confirmado: ${MaterialLocalizations.of(context).formatShortDate(summary.cashConfirmedAt!.toLocal())} · ${TimeOfDay.fromDateTime(summary.cashConfirmedAt!.toLocal()).format(context)}',
          ),
        ),
        if (summary.isNegative) ...[
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppBadge(
                  'Saldo negativo',
                  tone: AppTone.warning,
                  icon: Icons.warning_amber_rounded,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Las retiradas activas superan los ingresos. Revisa el historial del fondo.',
                  style: type.bodyMedium,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        BalanceTrendPanel(groupId: groupId, currency: group.currency),
        const SizedBox(height: AppSpacing.lg),
        AppHeroPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Resumen del grupo',
                style: type.headingMedium.copyWith(
                  color: AppColors.of(context).onHero,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppAdaptiveRow(
                minChildWidth: AppSpacing.coverLarge * 1.5,
                children: [
                  StatisticCard(
                    framed: true,
                    label: 'Total ingresado',
                    value: formatMoneyCents(
                      summary.incomeCents,
                      currency: group.currency,
                    ),
                    icon: Icons.south_west_rounded,
                  ),
                  StatisticCard(
                    framed: true,
                    label: 'Total retirado',
                    tone: AppTone.danger,
                    value: formatMoneyCents(
                      summary.withdrawalCents,
                      currency: group.currency,
                    ),
                    icon: Icons.north_east_rounded,
                  ),
                  StatisticCard(
                    framed: true,
                    label: 'Personas activas',
                    tone: AppTone.tertiary,
                    value: '${summary.activePersonsCount}',
                    icon: Icons.people_outline,
                    caption:
                        '${summary.inactivePersonsCount} inactivas · ${summary.totalPersonsCount} en total',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Últimos movimientos',
                      style: type.headingSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (summary.recentActivity.isEmpty)
                const EmptyState(
                  icon: Icons.auto_stories_outlined,
                  title: 'La historia está por empezar.',
                  description:
                      'Cuando registréis un movimiento, aparecerá aquí.',
                )
              else
                for (var i = 0; i < summary.recentActivity.length; i++) ...[
                  if (i != 0) const Divider(height: AppSpacing.xl),
                  _ActivityCard(
                    groupId: groupId,
                    currency: group.currency,
                    event: summary.recentActivity[i],
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        QuotaReportSection(
          groupId: groupId,
          currency: group.currency,
          dashboard: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppNavigationTile(
          label: 'Cuotas y etapas',
          icon: Icons.calendar_month_outlined,
          description: 'Consulta la cuota y los periodos de participación',
          onTap: () => context.push('/groups/$groupId/quotas'),
        ),
        if (ref.watch(canEditGroupProvider(groupId))) ...[
          const SizedBox(height: AppSpacing.md),
          AppNavigationTile(
            label: 'Editar grupo',
            icon: Icons.tune_rounded,
            description: 'Cambia el nombre y la descripción del espacio',
            onTap: () => context.push('/groups/$groupId/settings'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppNavigationTile(
            label: 'Historial administrativo',
            icon: Icons.history_rounded,
            description: 'Consulta quién cambió qué y cuándo',
            onTap: () => context.push('/groups/$groupId/audit'),
          ),
        ],
      ],
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  const _ActivityCard({
    required this.groupId,
    required this.currency,
    required this.event,
  });
  final String groupId, currency;
  final DashboardActivity event;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTypography.of(context),
        labels = ref.watch(movementLabelsProvider(groupId));
    final date = event.at.toLocal(), l = MaterialLocalizations.of(context);
    final title = switch (event.kind) {
      DashboardActivityKind.registered =>
        event.input.type == MovementType.income
            ? 'Ingreso registrado'
            : 'Retirada registrada',
      DashboardActivityKind.cancelled => 'Movimiento anulado',
      DashboardActivityKind.corrected => 'Movimiento corregido',
    };
    final amount = MoneyText(
      event.input.amountCents,
      currency: currency,
      variant: event.input.type == MovementType.income
          ? MoneyTextVariant.income
          : MoneyTextVariant.withdrawal,
    );
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return AppReveal(
      key: ValueKey('${event.movementId}/${event.kind.name}'),
      child: Semantics(
        button: true,
        label: '$title. Ver movimiento',
        child: InkWell(
          borderRadius: AppRadius.control,
          onTap: () => context.push(
            '/groups/$groupId/movements?focus=${Uri.encodeQueryComponent(event.movementId)}',
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.input.personId != null)
                  PhotoAvatar(
                    target: PhotoTarget.person(groupId, event.input.personId!),
                    name: labels.person(event.input.personId),
                  )
                else
                  AppAvatar(name: labels.person(null)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labels.person(event.input.personId),
                        style: t.labelLarge,
                      ),
                      if (largeText) amount,
                      if (event.kind != DashboardActivityKind.registered) ...[
                        const SizedBox(height: AppSpacing.xs),
                        AppBadge(title, tone: AppTone.warning),
                      ],
                      if (event.reason != null)
                        Text(event.reason!, style: t.bodySmall)
                      else if (event.input.description.isNotEmpty)
                        Text(event.input.description, style: t.bodySmall),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${labels.author(event.actorUid)} · ${l.formatMediumDate(date)} · ${l.formatTimeOfDay(TimeOfDay.fromDateTime(date), alwaysUse24HourFormat: true)}',
                        style: t.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (!largeText) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(child: amount),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppSpacing.icon,
                  color: AppColors.of(context).textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
