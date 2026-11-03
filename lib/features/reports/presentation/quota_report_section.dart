import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/quota_report.dart';
import '../../../models/photo_target.dart';
import '../../photos/presentation/photo_view.dart';
import '../../movements/providers/movement_providers.dart';
import '../../persons/providers/person_providers.dart';
import '../../quotas/providers/quota_providers.dart';
import '../providers/quota_report_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';

String quotaPersonStatusLabel(QuotaPersonStatus status) => switch (status) {
  QuotaPersonStatus.paid => 'Al día',
  QuotaPersonStatus.partial => 'Parcial',
  QuotaPersonStatus.pending => 'Pendiente',
  QuotaPersonStatus.incomplete => 'Sin configurar',
  QuotaPersonStatus.notApplicable => 'Sin cuota computable',
};
String quotaCoverageLabel(int? points) => points == null
    ? 'Sin porcentaje calculable'
    : '${points ~/ 100},${(points % 100) ~/ 10} %';

class QuotaReportSection extends ConsumerWidget {
  const QuotaReportSection({
    super.key,
    required this.groupId,
    required this.currency,
    this.dashboard = false,
  });
  final String groupId, currency;
  final bool dashboard;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = dashboard
        ? ref.watch(dashboardQuotaReportProvider(groupId))
        : ref.watch(quotaReportProvider(groupId));
    return state.when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      loading: () =>
          const LoadingIndicator(label: 'Reuniendo el cumplimiento de cuotas…'),
      error: (e, _) => AppCard(
        child: EmptyState(
          icon: Icons.calendar_month_outlined,
          title: 'Cuotas no disponibles',
          description: failureMessage(e),
          actionLabel: 'Actualizar cuotas',
          onAction: () {
            ref.invalidate(groupQuotaPeriodsProvider(groupId));
            ref.invalidate(groupQuotaAllocationsProvider(groupId));
            ref.invalidate(quotaRulesProvider(groupId));
            ref.invalidate(personsProvider(groupId));
            ref.invalidate(movementsProvider(groupId));
            ref.invalidate(quotaSourceMovementsProvider(groupId));
          },
        ),
      ),
      data: (report) => dashboard
          ? _DashboardQuotas(
              groupId: groupId,
              currency: currency,
              report: report,
            )
          : _QuotaReportBody(currency: currency, report: report),
    );
  }
}

class _DashboardQuotas extends ConsumerWidget {
  const _DashboardQuotas({
    required this.groupId,
    required this.currency,
    required this.report,
  });
  final String groupId, currency;
  final QuotaReport report;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTypography.of(context),
        c = AppColors.of(context).onHero,
        totals = report.accumulated.totals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppReveal(
          child: AppHeroPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Las cuotas de tu comunidad',
                  style: t.editorialTitle.copyWith(color: c),
                ),
                Text(
                  'Por cubrir hasta ${report.currentMonth}',
                  style: t.bodyMedium.copyWith(color: c),
                ),
                if (totals.pendingCents case final cents?)
                  MoneyText(cents, currency: currency, color: c)
                else
                  Text(
                    'Configuración incompleta',
                    style: t.headingSmall.copyWith(color: c),
                  ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Estado actualizado de todos los meses computables, incluidas personas inactivas con historial.',
                  style: t.bodySmall.copyWith(color: c),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PeopleSummary(summary: report.accumulated),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Este mes · ${report.currentMonth}', style: t.headingSmall),
              const SizedBox(height: AppSpacing.md),
              _QuotaAmounts(
                summary: report.elapsed,
                currency: currency,
                showPeople: false,
              ),
              ref
                  .watch(dashboardCashProvider(groupId))
                  .when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (cash) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(height: AppSpacing.xl),
                        Text(
                          'Dinero recibido y retirado este mes',
                          style: t.labelLarge,
                        ),
                        Text(
                          'Ingresos ${formatMoneyCents(cash.monthIncomeCents, currency: currency)} · Retiradas ${formatMoneyCents(cash.monthWithdrawalCents, currency: currency)}',
                          style: t.bodyMedium,
                        ),
                        Text(
                          'Por fecha efectiva. Los pagos de cuotas se cuentan en el mes al que se asignan.',
                          style: t.bodySmall,
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuotaReportBody extends StatelessWidget {
  const _QuotaReportBody({required this.currency, required this.report});
  final String currency;
  final QuotaReport report;
  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text('Lo que cubren las aportaciones', style: t.editorialTitle),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Cuotas de ${report.firstMonth} a ${report.lastMonth}, con los pagos y devoluciones registrados hasta hoy. Los meses posteriores a ${report.currentMonth} son previsión.',
          style: t.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppReveal(
          child: AppCard(
            child: _QuotaAmounts(summary: report.elapsed, currency: currency),
          ),
        ),
        if (report.hasForecast) ...[
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppBadge('Meses futuros · Previsión', tone: AppTone.info),
                const SizedBox(height: AppSpacing.md),
                _QuotaAmounts(
                  summary: report.forecast,
                  currency: currency,
                  forecast: true,
                  showPeople: false,
                ),
                Text(
                  'No se suman al pendiente hasta el mes actual. La previsión usa las cuotas programadas y las etapas conocidas; puede cambiar.',
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Crédito actual del grupo', style: t.headingSmall),
              Text(
                'Sin asignar: ${formatMoneyCents(report.unallocatedCreditCents, currency: currency)}',
                style: t.bodyMedium,
              ),
              Text(
                'Asignado a meses futuros: ${formatMoneyCents(report.futureCreditCents, currency: currency)}',
                style: t.bodyMedium,
              ),
              Text(
                'Estos créditos corresponden a todo el historial actual del grupo, no solo al periodo seleccionado. El dinero sin asignar no paga cuotas.',
                style: t.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: AppExpandableRow(
            title: Text('Mes a mes', style: t.headingSmall),
            children: [
              AppPairedBars(
                firstLabel: 'Esperado conocido',
                secondLabel: 'Cuota cubierta',
                entries: [
                  for (final month in report.months)
                    AppBarPair(
                      label:
                          '${month.month}${month.isFuture ? ' · Previsión' : ''}${month.summary.totals.isComplete ? '' : ' · Incompleto'}',
                      first: month.summary.totals.knownExpectedCents,
                      second: month.summary.totals.coveredCents,
                      firstText: formatMoneyCents(
                        month.summary.totals.knownExpectedCents,
                        currency: currency,
                      ),
                      secondText: formatMoneyCents(
                        month.summary.totals.coveredCents,
                        currency: currency,
                      ),
                    ),
                ],
              ),
              for (final month in report.months)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    '${month.month} · ${month.isFuture ? 'Previsión por cubrir' : 'Pendiente'}: ${month.summary.totals.pendingCents == null ? 'Sin determinar' : formatMoneyCents(month.summary.totals.pendingCents!, currency: currency)}',
                    style: t.bodySmall,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Cada persona, su recorrido', style: t.headingSmall),
        if (report.persons.isEmpty)
          Text('Este grupo todavía no tiene personas.', style: t.bodyMedium),
        for (final row in report.persons)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: AppCard(
              child: AppExpandableRow(
                leading: PhotoAvatar(
                  target: PhotoTarget.person(report.groupId, row.person.id),
                  name: row.person.displayName,
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.person.displayName, style: t.labelLarge),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        AppBadge(quotaPersonStatusLabel(row.elapsed.status)),
                        if (!row.person.isActive) const AppBadge('Inactiva'),
                      ],
                    ),
                  ],
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Periodo hasta el mes actual',
                          style: t.labelLarge,
                        ),
                        Text(
                          'Esperado conocido: ${formatMoneyCents(row.elapsed.knownExpectedCents, currency: currency)}',
                          style: t.bodyMedium,
                        ),
                        Text(
                          'Asignado neto: ${formatMoneyCents(row.elapsed.allocatedCents, currency: currency)}',
                          style: t.bodyMedium,
                        ),
                        Text(
                          'Pendiente: ${row.elapsed.pendingCents == null ? 'Sin determinar' : formatMoneyCents(row.elapsed.pendingCents!, currency: currency)}',
                          style: t.bodyMedium,
                        ),
                        if (report.hasForecast)
                          Text(
                            'Previsión futura conocida: ${formatMoneyCents(row.forecast.knownExpectedCents, currency: currency)} · Asignado ${formatMoneyCents(row.forecast.allocatedCents, currency: currency)}',
                            style: t.bodySmall,
                          ),
                        AppButton(
                          label: 'Ver ficha de ${row.person.displayName}',
                          variant: AppButtonVariant.ghost,
                          onPressed: () => context.push(
                            '/groups/${report.groupId}/persons/${row.person.id}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _QuotaAmounts extends StatelessWidget {
  const _QuotaAmounts({
    required this.summary,
    required this.currency,
    this.forecast = false,
    this.showPeople = true,
  });
  final QuotaGroupSlice summary;
  final String currency;
  final bool forecast, showPeople;
  @override
  Widget build(BuildContext context) {
    final totals = summary.totals, t = AppTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppAdaptiveRow(
          children: [
            StatisticCard(
              framed: false,
              label: totals.isComplete ? 'Cuota esperada' : 'Esperado conocido',
              value: formatMoneyCents(
                totals.knownExpectedCents,
                currency: currency,
              ),
              icon: Icons.calendar_month_outlined,
            ),
            StatisticCard(
              framed: false,
              label: 'Asignado neto',
              value: formatMoneyCents(
                totals.allocatedCents,
                currency: currency,
              ),
              icon: Icons.check_circle_outline,
            ),
            StatisticCard(
              framed: false,
              label: forecast ? 'Previsión por cubrir' : 'Pendiente',
              value: totals.pendingCents == null
                  ? 'Sin determinar'
                  : formatMoneyCents(totals.pendingCents!, currency: currency),
              icon: Icons.hourglass_empty_rounded,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Cumplimiento · ${quotaCoverageLabel(totals.coverageBasisPoints)}',
          style: t.headingSmall,
        ),
        Text(
          'Solo cuenta lo que cubre la cuota de cada mes. Los sobrepagos no cubren otros meses ni elevan el porcentaje por encima del 100 %.',
          style: t.bodySmall,
        ),
        if (totals.overpaidCents > 0)
          Text(
            'Sobrepago conocido: ${formatMoneyCents(totals.overpaidCents, currency: currency)}',
            style: t.bodyMedium,
          ),
        if (!totals.isComplete) ...[
          const SizedBox(height: AppSpacing.md),
          const AppBadge('Configuración incompleta', tone: AppTone.warning),
          Text(
            'Faltan periodos o cuotas. Los importes conocidos no son el total esperado y el pendiente no se puede determinar.',
            style: t.bodySmall,
          ),
        ],
        if (showPeople) ...[
          const SizedBox(height: AppSpacing.lg),
          _PeopleSummary(summary: summary),
        ],
      ],
    );
  }
}

class _PeopleSummary extends StatelessWidget {
  const _PeopleSummary({required this.summary});
  final QuotaGroupSlice summary;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      for (final status in QuotaPersonStatus.values)
        AppBadge(
          '${quotaPersonStatusLabel(status)}: ${summary.count(status)}',
          tone: status == QuotaPersonStatus.incomplete
              ? AppTone.warning
              : status == QuotaPersonStatus.paid
              ? AppTone.success
              : AppTone.neutral,
        ),
    ],
  );
}
