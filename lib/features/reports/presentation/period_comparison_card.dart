import 'package:flutter/material.dart';
import '../../../design_system/design_system.dart';
import '../../../models/report_comparison.dart';
import 'quota_report_section.dart';

String _signedPercentage(BigInt basisPoints) {
  final absolute = basisPoints.abs();
  final sign = basisPoints.isNegative
      ? '−'
      : basisPoints == BigInt.zero
      ? ''
      : '+';
  return '$sign${absolute ~/ BigInt.from(100)},${(absolute % BigInt.from(100)) ~/ BigInt.from(10)}';
}

class PeriodComparisonCard extends StatelessWidget {
  const PeriodComparisonCard({
    super.key,
    required this.comparison,
    required this.currency,
  });
  final PeriodComparison comparison;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final colors = AppColors.of(context);
    final dates = MaterialLocalizations.of(context);
    String range(ComparisonWindow window) =>
        '${dates.formatMediumDate(window.start)} – ${dates.formatMediumDate(window.endExclusive.subtract(const Duration(days: 1)))}';
    final coverage = comparison.coverage;
    return AppReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeroPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Una mirada al periodo anterior',
                  style: t.editorialTitle.copyWith(color: colors.onHero),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Ahora · ${range(comparison.currentWindow)}',
                  style: t.bodyMedium.copyWith(color: colors.onHero),
                ),
                Text(
                  'Antes · ${range(comparison.previousWindow)}',
                  style: t.bodyMedium.copyWith(color: colors.onHero),
                ),
                if (comparison.isPartial) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Periodo en curso: mismo tramo transcurrido. Si el mes anterior es más corto, el tramo termina en su último día.',
                    style: t.bodySmall.copyWith(color: colors.onHero),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Dinero por fecha efectiva', style: t.headingSmall),
          const SizedBox(height: AppSpacing.md),
          AppAdaptiveRow(
            children: [
              _MoneyChange(
                label: 'Ingresos',
                change: comparison.income,
                currency: currency,
              ),
              _MoneyChange(
                label: 'Retiradas',
                change: comparison.withdrawals,
                currency: currency,
              ),
              _MoneyChange(
                label: 'Neto del tramo',
                change: comparison.netCash,
                currency: currency,
                showRelative: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Cuotas por mes asignado', style: t.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Cada mes computable se cuenta completo, sin prorratear por día. Pagos y devoluciones están actualizados hasta hoy; los meses futuros quedan fuera.',
            style: t.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppAdaptiveRow(
            children: [
              _MoneyChange(
                label: 'Cuota esperada',
                change: comparison.expectedQuota,
                currency: currency,
              ),
              _MoneyChange(
                label: 'Pagos asignados netos',
                change: comparison.paidQuota,
                currency: currency,
              ),
              _MoneyChange(
                label: 'Pendiente de cuota',
                change: comparison.pendingQuota,
                currency: currency,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Cumplimiento', style: t.headingSmall),
                Text(
                  'Ahora: ${quotaCoverageLabel(coverage.current)}',
                  style: t.bodyMedium,
                ),
                Text(
                  'Antes: ${quotaCoverageLabel(coverage.previous)}',
                  style: t.bodyMedium,
                ),
                Text(
                  coverage.difference == null
                      ? 'Cambio sin determinar: configuración incompleta o cuota esperada cero.'
                      : 'Cambio: ${_signedPercentage(BigInt.from(coverage.difference!))} puntos porcentuales.',
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Una subida o bajada describe la diferencia, sin calificarla automáticamente como buena o mala. Son datos actuales del historial, no cierres contables.',
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MoneyChange extends StatelessWidget {
  const _MoneyChange({
    required this.label,
    required this.change,
    required this.currency,
    this.showRelative = true,
  });
  final String label, currency;
  final ReportMetricChange change;
  final bool showRelative;
  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    String money(int? cents) => cents == null
        ? 'Sin determinar'
        : formatMoneyCents(cents, currency: currency);
    final delta = change.difference;
    final percent = change.relativeChangeBasisPoints;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: t.labelLarge),
          const SizedBox(height: AppSpacing.md),
          Text(money(change.current), style: t.headingMedium),
          Text('Antes: ${money(change.previous)}', style: t.bodySmall),
          const Divider(height: AppSpacing.lg),
          Text(
            delta == null
                ? 'Diferencia sin determinar'
                : 'Diferencia: ${delta > 0 ? '+' : ''}${money(delta)}',
            style: t.bodyMedium,
          ),
          if (showRelative)
            Text(
              percent == null
                  ? 'Sin porcentaje comparable'
                  : '${_signedPercentage(percent)} % respecto al anterior',
              style: t.bodySmall,
            ),
        ],
      ),
    );
  }
}
