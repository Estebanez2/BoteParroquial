import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../providers/report_comparison_providers.dart';
import 'period_comparison_card.dart';

class ReportComparisonSection extends StatelessWidget {
  const ReportComparisonSection({
    super.key,
    required this.groupId,
    required this.currency,
  });
  final String groupId, currency;
  @override
  Widget build(BuildContext context) => AppExpandableRow(
    title: Text(
      'Comparar con el periodo anterior',
      style: AppTypography.of(context).headingSmall,
    ),
    leading: const Icon(Icons.compare_arrows_rounded),
    children: [
      Consumer(
        builder: (context, ref, _) => ref
            .watch(reportComparisonProvider(groupId))
            .when(
              skipLoadingOnReload: false,
              skipLoadingOnRefresh: false,
              loading: () =>
                  const LoadingIndicator(label: 'Preparando comparación…'),
              error: (error, _) => AppCard(
                child: EmptyState(
                  icon: Icons.compare_arrows_rounded,
                  title: 'Comparación no disponible',
                  description: failureMessage(error),
                ),
              ),
              data: (comparison) => comparison == null
                  ? AppCard(
                      child: Text(
                        'Selecciona un periodo que ya haya comenzado y tenga un periodo anterior dentro del intervalo disponible desde el año 2000.',
                        style: AppTypography.of(context).bodyMedium,
                      ),
                    )
                  : PeriodComparisonCard(
                      comparison: comparison,
                      currency: currency,
                    ),
            ),
      ),
    ],
  );
}
