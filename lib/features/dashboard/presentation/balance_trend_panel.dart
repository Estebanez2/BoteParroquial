import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../providers/dashboard_providers.dart';
import '../../offline/presentation/daily_copies_screen.dart';

class BalanceTrendPanel extends ConsumerWidget {
  const BalanceTrendPanel({
    super.key,
    required this.groupId,
    required this.currency,
  });
  final String groupId, currency;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTypography.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Así evoluciona vuestro bote',
                  style: t.headingSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Últimos seis meses · El mes actual sigue en curso',
            style: t.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          ref
              .watch(dashboardTrendProvider(groupId))
              .when(
                skipLoadingOnRefresh: false,
                skipLoadingOnReload: false,
                loading: () => const AppShimmer(
                  label: 'Preparando evolución del saldo',
                  child: AppSkeletonBlock(height: AppSpacing.chartHeight),
                ),
                error: (error, _) => DailyCopyRecovery(
                  error: error,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(failureMessage(error), style: t.bodySmall),
                      AppButton(
                        label: 'Actualizar gráfica',
                        variant: AppButtonVariant.outline,
                        onPressed: () =>
                            ref.invalidate(dashboardCashProvider(groupId)),
                      ),
                    ],
                  ),
                ),
                data: (points) => AppLineChart(
                  labels: [
                    for (final p in points)
                      DateFormat.MMM(
                        Localizations.localeOf(context).toLanguageTag(),
                      ).format(p.month.firstDayUtc),
                  ],
                  values: [for (final p in points) p.balanceCents],
                  valueLabels: [
                    for (final p in points)
                      formatMoneyCents(p.balanceCents, currency: currency),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
