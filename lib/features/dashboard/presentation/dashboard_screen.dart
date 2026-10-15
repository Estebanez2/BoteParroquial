import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/dashboard_summary.dart';
import '../../../models/group.dart';
import '../../../models/group_member.dart';
import '../../../models/movement.dart';
import '../../groups/presentation/group_access_body.dart';
import '../../groups/presentation/group_widgets.dart';
import '../../movements/providers/movement_providers.dart';
import '../../persons/providers/person_providers.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context) => AppScaffold(
    maxWidth: AppSpacing.readingMax,
    appBar: AppTopBar(
      title: 'Tu espacio',
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
    final type = AppTypography.of(context);
    final groupId = group.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('LO NUESTRO, DE UN VISTAZO', style: type.labelSmall),
        const SizedBox(height: AppSpacing.md),
        AppReveal(child: Text(group.name, style: type.displayLarge)),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppBadge(roleLabel(membership.role), tone: AppTone.primary),
            AppBadge(group.currency),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(
              label: 'Ver movimientos',
              variant: AppButtonVariant.outline,
              leadingIcon: Icons.receipt_long_outlined,
              onPressed: () => context.push('/groups/$groupId/movements'),
            ),
            AppButton(
              label: 'Ver personas',
              variant: AppButtonVariant.ghost,
              leadingIcon: Icons.people_outline,
              onPressed: () => context.push('/groups/$groupId/persons'),
            ),
            AppButton(
              label: 'Ver miembros',
              variant: AppButtonVariant.ghost,
              leadingIcon: Icons.group_outlined,
              onPressed: () => context.push('/groups/$groupId/members'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
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
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                label: 'Registrar ingreso',
                leadingIcon: Icons.south_west_rounded,
                onPressed: () =>
                    context.push('/groups/$groupId/movements/new?type=income'),
              ),
              AppButton(
                label: 'Registrar retirada',
                variant: AppButtonVariant.outline,
                leadingIcon: Icons.north_east_rounded,
                onPressed: () => context.push(
                  '/groups/$groupId/movements/new?type=withdrawal',
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.section),
        Text('La historia en cifras', style: type.headingMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Totales de todo el historial, descontando anulaciones y originales corregidos.',
          style: type.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final income = StatisticCard(
              label: 'Total ingresado',
              value: formatMoneyCents(
                summary.incomeCents,
                currency: group.currency,
              ),
              icon: Icons.south_west_rounded,
            );
            final withdrawal = StatisticCard(
              label: 'Total retirado',
              value: formatMoneyCents(
                summary.withdrawalCents,
                currency: group.currency,
              ),
              icon: Icons.north_east_rounded,
            );
            if (constraints.maxWidth >=
                AppSpacing.readingMax - AppSpacing.page * 2) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: income),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: withdrawal),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                income,
                const SizedBox(height: AppSpacing.lg),
                withdrawal,
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        StatisticCard(
          label: 'Personas activas',
          value: '${summary.activePersonsCount}',
          icon: Icons.people_outline,
          caption:
              '${summary.inactivePersonsCount} inactivas · ${summary.totalPersonsCount} en total',
        ),
        const SizedBox(height: AppSpacing.section),
        Text('Lo último que ha pasado', style: type.headingMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Últimos cambios de movimientos por fecha de registro. Las correcciones aparecen una sola vez.',
          style: type.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (summary.recentActivity.isEmpty)
          const EmptyState(
            icon: Icons.auto_stories_outlined,
            title: 'La historia está por empezar.',
            description: 'Cuando registréis un movimiento, aparecerá aquí.',
          )
        else
          for (final event in summary.recentActivity)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _ActivityCard(
                groupId: groupId,
                currency: group.currency,
                event: event,
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
    final type = AppTypography.of(context),
        labels = ref.watch(movementLabelsProvider(groupId));
    final localDate = event.at.toLocal(),
        localization = MaterialLocalizations.of(context);
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
      child: AppCard(
        variant: AppCardVariant.interactive,
        onTap: () => context.push(
          '/groups/$groupId/movements?focus=${Uri.encodeQueryComponent(event.movementId)}',
        ),
        semanticLabel: '$title. Ver movimiento',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppBadge(
              title,
              tone: event.kind == DashboardActivityKind.cancelled
                  ? AppTone.warning
                  : AppTone.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            MoneyText(
              event.input.amountCents,
              currency: currency,
              variant: event.input.type == MovementType.income
                  ? MoneyTextVariant.income
                  : MoneyTextVariant.withdrawal,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(labels.person(event.input.personId), style: type.headingSmall),
            if (event.reason != null)
              Text(event.reason!, style: type.bodyMedium)
            else if (event.input.description.isNotEmpty)
              Text(event.input.description, style: type.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${labels.author(event.actorUid)} · ${localization.formatMediumDate(localDate)} · ${localization.formatTimeOfDay(TimeOfDay.fromDateTime(localDate), alwaysUse24HourFormat: true)}',
              style: type.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Ver movimiento ↗', style: type.labelMedium),
          ],
        ),
      ),
    );
  }
}
