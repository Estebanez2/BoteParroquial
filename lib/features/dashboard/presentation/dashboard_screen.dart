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

import '../../movements/providers/movement_providers.dart';
import '../../movements/presentation/pending_movement_card.dart';
import '../../persons/providers/person_providers.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context) => AppScaffold(
    maxWidth: AppSpacing.readingMax,
    appBar: AppTopBar(
      title: 'BoteParroquial',
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver a mis grupos',
        onPressed: () => context.go('/'),
      ),
    ),
    child: GroupAccessBody(
      groupId: groupId,
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
              loading: () =>
                  const LoadingIndicator(label: 'Actualizando el resumen…'),
              error: (error, _) => EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'No pudimos preparar el resumen',
                description: failureMessage(error),
                actionLabel: 'Reintentar resumen',
                onAction: () {
                  ref.invalidate(movementsProvider(groupId));
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
    final canManage = ref.watch(canManageMovementsProvider(groupId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppReveal(
          child: BalanceCard(
            balanceCents: summary.balanceCents,
            currency: group.currency,
            caption: 'Todo el historial · Solo movimientos activos',
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
        if (canManage) ...[
          const SizedBox(height: AppSpacing.xl),
          AppAdaptiveRow(
            children: [
              AppButton(
                label: 'Registrar ingreso',
                fullWidth: true,
                trailingIcon: Icons.chevron_right_rounded,
                leadingIcon: Icons.add_rounded,
                onPressed: () =>
                    context.push('/groups/$groupId/movements/new?type=income'),
              ),
              AppButton(
                label: 'Registrar retirada',
                fullWidth: true,
                variant: AppButtonVariant.outline,
                leadingIcon: Icons.north_east_rounded,
                onPressed: () => context.push(
                  '/groups/$groupId/movements/new?type=withdrawal',
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppAdaptiveRow(
          children: [
            AppNavigationTile(
              label: 'Ver movimientos',
              icon: Icons.receipt_long_outlined,
              onTap: () => context.push('/groups/$groupId/movements'),
            ),
            AppNavigationTile(
              label: 'Ver personas',
              icon: Icons.people_outline,
              onTap: () => context.push('/groups/$groupId/persons'),
            ),
            AppNavigationTile(
              label: 'Ver miembros',
              icon: Icons.groups_outlined,
              onTap: () => context.push('/groups/$groupId/members'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('La historia en cifras', style: type.headingSmall),
              const SizedBox(height: AppSpacing.xl),
              AppAdaptiveRow(
                children: [
                  StatisticCard(
                    framed: false,
                    label: 'Total ingresado',
                    value: formatMoneyCents(
                      summary.incomeCents,
                      currency: group.currency,
                    ),
                    icon: Icons.south_west_rounded,
                  ),
                  StatisticCard(
                    framed: false,
                    label: 'Total retirado',
                    value: formatMoneyCents(
                      summary.withdrawalCents,
                      currency: group.currency,
                    ),
                    icon: Icons.north_east_rounded,
                  ),
                  StatisticCard(
                    framed: false,
                    label: 'Personas activas',
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
                      'Lo último que ha pasado',
                      style: type.headingSmall,
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.chevron_right_rounded,
                    label: 'Ver todo el historial',
                    variant: AppIconButtonVariant.ghost,
                    onPressed: () => context.push('/groups/$groupId/movements'),
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
                      AppBadge(
                        title,
                        tone: event.kind == DashboardActivityKind.cancelled
                            ? AppTone.warning
                            : AppTone.primary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      MoneyText(
                        event.input.amountCents,
                        currency: currency,
                        variant: event.input.type == MovementType.income
                            ? MoneyTextVariant.income
                            : MoneyTextVariant.withdrawal,
                      ),
                      Text(
                        labels.person(event.input.personId),
                        style: t.labelLarge,
                      ),
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
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
