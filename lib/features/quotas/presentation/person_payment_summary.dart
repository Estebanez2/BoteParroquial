import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/quota_settlement.dart';
import '../../movements/providers/movement_providers.dart';
import '../providers/allocation_providers.dart';

class PersonPaymentSummary extends ConsumerWidget {
  const PersonPaymentSummary({
    super.key,
    required this.groupId,
    required this.personId,
    required this.currency,
  });
  final String groupId, personId, currency;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(personQuotaSettlementProvider((groupId, personId)))
      .when(
        loading: () =>
            const LoadingIndicator(label: 'Reuniendo cuotas y aportaciones…'),
        error: (e, _) => Column(
          children: [
            Text(failureMessage(e)),
            AppButton(
              label: 'Actualizar pagos',
              variant: AppButtonVariant.ghost,
              onPressed: () {
                ref.invalidate(allocationsProvider((groupId, personId)));
                ref.invalidate(movementsProvider(groupId));
              },
            ),
          ],
        ),
        data: (s) {
          final t = AppTypography.of(context);
          final heroColor = AppColors.of(context).onHero;
          Widget amount(String label, int value) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: t.bodySmall),
              MoneyText(value, currency: currency),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppReveal(
                child: AppHeroPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lo que queda por cubrir',
                        style: t.headingSmall.copyWith(color: heroColor),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (s.pendingCents != null)
                        MoneyText(
                          s.pendingCents!,
                          currency: currency,
                          color: heroColor,
                        )
                      else
                        Text(
                          'Configuración incompleta',
                          style: t.headingSmall.copyWith(color: heroColor),
                        ),
                      Text(
                        'Hasta ${s.currentMonth} · Solo pagos asignados a cada mes',
                        style: t.bodySmall.copyWith(color: heroColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppAdaptiveRow(
                children: [
                  amount(
                    s.isComplete
                        ? 'Cuota acumulada esperada'
                        : 'Importe esperado conocido',
                    s.knownExpectedCents,
                  ),
                  amount(
                    'Asignado hasta este mes',
                    s.allocatedThroughCurrentCents,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppAdaptiveRow(
                children: [
                  amount('Crédito futuro', s.futureCreditCents),
                  amount('Crédito sin asignar', s.unallocatedCreditCents),
                ],
              ),
              if (s.differenceCents != null) ...[
                const SizedBox(height: AppSpacing.lg),
                amount(
                  'Diferencia: asignado menos esperado',
                  s.differenceCents!,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                'El dinero sin asignar cuenta en el bote, pero no paga meses. Un sobrepago de un mes no cubre otro automáticamente. Una retirada normal no cambia cuotas; una devolución vinculada sí descuenta los pagos elegidos.',
                style: t.bodySmall,
              ),
              if (s.incomes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Aportaciones para repartir', style: t.headingSmall),
                for (final income in s.incomes)
                  AppButton(
                    label:
                        '${MaterialLocalizations.of(context).formatMediumDate(income.movement.input.occurredAt)} · ${formatMoneyCents(income.unallocatedCents, currency: currency)} sin asignar',
                    variant: AppButtonVariant.ghost,
                    leadingIcon: Icons.calendar_month_outlined,
                    onPressed: () => context.push(
                      '/groups/$groupId/movements/${income.movement.id}/allocations',
                    ),
                  ),
              ],
            ],
          );
        },
      );
}

String quotaPaymentLabel(MonthQuotaPayment row) => switch (row.state) {
  QuotaPaymentState.incomplete => 'Configuración incompleta',
  QuotaPaymentState.notApplicable => 'No computable',
  QuotaPaymentState.suspended => 'Sin cuota',
  QuotaPaymentState.pending => row.isFuture ? 'Próxima cuota' : 'Pendiente',
  QuotaPaymentState.partial => row.isFuture ? 'Adelanto parcial' : 'Parcial',
  QuotaPaymentState.paid => row.isFuture ? 'Adelantado' : 'Pagado',
  QuotaPaymentState.overpaid =>
    row.isFuture ? 'Adelantado con exceso' : 'Sobrepago',
};
