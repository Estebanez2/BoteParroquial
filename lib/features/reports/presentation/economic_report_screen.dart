import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/economic_report.dart';
import '../../../models/report_export.dart';
import '../../groups/presentation/group_access_body.dart';
import '../../movements/providers/movement_providers.dart';
import '../../persons/providers/person_providers.dart';
import '../providers/report_providers.dart';
import '../providers/csv_export_providers.dart';
import '../../groups/providers/group_management_providers.dart';
import 'quota_report_section.dart';
import 'report_comparison_section.dart';

const reportMonthNames = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

class EconomicReportScreen extends ConsumerWidget {
  const EconomicReportScreen({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    maxWidth: AppSpacing.readingMax,
    appBar: AppTopBar(
      title: 'Informes',
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver al grupo',
        onPressed: () => context.go('/groups/$groupId'),
      ),
    ),
    child: GroupAccessBody(
      groupId: groupId,
      builder: (group, _) {
        final selection = ref.watch(reportSelectionProvider(groupId));
        final controller = ref.read(reportSelectionProvider(groupId).notifier);
        final type = AppTypography.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('La historia en cifras', style: type.editorialTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Los movimientos se ordenan por fecha efectiva. Las cuotas se cuentan en el mes al que se asigna cada pago.',
              style: type.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppChoiceBar<ReportPeriod>(
              options: const {
                ReportPeriod.month: 'Mes',
                ReportPeriod.quarter: 'Trimestre',
                ReportPeriod.year: 'Año',
              },
              value: selection.period,
              onChanged: (value) => controller.select(period: value),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppAdaptiveRow(
              children: [
                AppDropdown<int>(
                  label: 'Año',
                  value: selection.year,
                  options: {
                    for (
                      var year = controller.currentYear();
                      year >= 2000;
                      year--
                    )
                      year: '$year',
                  },
                  onChanged: (value) {
                    if (value != null) controller.select(year: value);
                  },
                ),
                if (selection.period != ReportPeriod.year)
                  AppDropdown<int>(
                    label: selection.period == ReportPeriod.month
                        ? 'Mes'
                        : 'Trimestre',
                    value: selection.period == ReportPeriod.month
                        ? selection.month
                        : selection.startMonth,
                    options: selection.period == ReportPeriod.month
                        ? {
                            for (var month = 1; month <= 12; month++)
                              month: reportMonthNames[month - 1],
                          }
                        : const {
                            1: 'Enero – marzo',
                            4: 'Abril – junio',
                            7: 'Julio – septiembre',
                            10: 'Octubre – diciembre',
                          },
                    onChanged: (value) {
                      if (value != null) controller.select(month: value);
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (ref.watch(canEditGroupProvider(groupId))) ...[
              AppDropdown<ReportExportFormat>(
                label: 'Formato de exportación',
                value: ref.watch(reportExportFormatProvider(groupId)),
                options: const {
                  ReportExportFormat.pdf: 'PDF · informe',
                  ReportExportFormat.xlsx: 'Excel · hojas de cálculo',
                  ReportExportFormat.csv: 'CSV · movimientos',
                },
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(reportExportFormatProvider(groupId).notifier)
                        .select(value);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Exportar y compartir',
                leadingIcon: Icons.ios_share_rounded,
                variant: AppButtonVariant.outline,
                loading: ref.watch(csvExportProvider(groupId)).isLoading,
                onPressed: () =>
                    ref.read(csvExportProvider(groupId).notifier).export(),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'PDF: resumen y movimientos. Excel: resumen, personas, movimientos y actividad mensual. CSV: movimientos en céntimos. Se consultará el historial en el servidor antes de compartir.',
                style: type.bodySmall,
              ),
              if (ref.watch(csvExportProvider(groupId)).hasError)
                Text(
                  failureMessage(ref.watch(csvExportProvider(groupId)).error!),
                  style: type.bodyMedium,
                ),
              const SizedBox(height: AppSpacing.lg),
            ],
            ref
                .watch(economicReportProvider(groupId))
                .when(
                  skipLoadingOnRefresh: false,
                  skipLoadingOnReload: false,
                  loading: () =>
                      const LoadingIndicator(label: 'Preparando informe…'),
                  error: (error, _) => EmptyState(
                    icon: Icons.error_outline,
                    title: 'No pudimos preparar el informe',
                    description: failureMessage(error),
                    actionLabel: 'Reintentar',
                    onAction: () {
                      ref.invalidate(movementsProvider(groupId));
                      ref.invalidate(personsProvider(groupId));
                    },
                  ),
                  data: (report) => _ReportBody(
                    groupId: groupId,
                    currency: group.currency,
                    report: report,
                  ),
                ),
            QuotaReportSection(groupId: groupId, currency: group.currency),
            const SizedBox(height: AppSpacing.lg),
            ReportComparisonSection(groupId: groupId, currency: group.currency),
          ],
        );
      },
    ),
  );
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({
    required this.groupId,
    required this.currency,
    required this.report,
  });
  final String groupId, currency;
  final EconomicReport report;
  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context),
        locale = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${locale.formatMediumDate(report.start)} – ${locale.formatMediumDate(report.endExclusive.subtract(const Duration(days: 1)))}',
          style: type.labelLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        AppReveal(
          child: BalanceCard(
            balanceCents: report.closingCents,
            currency: currency,
            caption: 'Saldo al final del periodo · Estado actual del historial',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppAdaptiveRow(
          children: [
            StatisticCard(
              label: 'Saldo inicial',
              value: formatMoneyCents(report.openingCents, currency: currency),
              icon: Icons.history_rounded,
            ),
            StatisticCard(
              label: 'Ingresos',
              value: formatMoneyCents(report.incomeCents, currency: currency),
              icon: Icons.south_west_rounded,
            ),
            StatisticCard(
              label: 'Retiradas',
              value: formatMoneyCents(
                report.withdrawalCents,
                currency: currency,
              ),
              icon: Icons.north_east_rounded,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Actividad del periodo', style: type.headingSmall),
              const SizedBox(height: AppSpacing.lg),
              AppPairedBars(
                firstLabel: 'Ingresos',
                secondLabel: 'Retiradas',
                entries: [
                  for (final month in report.months)
                    AppBarPair(
                      label: reportMonthNames[month.month.month - 1],
                      first: month.incomeCents,
                      second: month.withdrawalCents,
                      firstText: formatMoneyCents(
                        month.incomeCents,
                        currency: currency,
                      ),
                      secondText: formatMoneyCents(
                        month.withdrawalCents,
                        currency: currency,
                      ),
                    ),
                ],
              ),
              Text(
                '${report.activeMovementsCount} movimientos activos en este periodo.',
                style: type.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Por persona', style: type.headingSmall),
              const SizedBox(height: AppSpacing.md),
              if (report.persons.isEmpty)
                Text(
                  'No hay movimientos activos en el periodo.',
                  style: type.bodyMedium,
                ),
              for (final person in report.persons)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(person.name, style: type.labelLarge),
                      if (person.personId != null && !person.isActive)
                        const AppBadge('Inactiva o no disponible'),
                      Text(
                        'Ingresos: ${formatMoneyCents(person.incomeCents, currency: currency)} · Retiradas: ${formatMoneyCents(person.withdrawalCents, currency: currency)}',
                        style: type.bodySmall,
                      ),
                      if (person.personId != null)
                        AppButton(
                          label: 'Ver ficha',
                          variant: AppButtonVariant.ghost,
                          onPressed: () => context.push(
                            '/groups/$groupId/persons/${person.personId}',
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Una anulación o corrección posterior actualiza estos resultados históricos. Los movimientos no acreditan cuotas pagadas: consulta su resumen a continuación. No son cierres contables inmutables.',
          style: type.bodySmall,
        ),
      ],
    );
  }
}
