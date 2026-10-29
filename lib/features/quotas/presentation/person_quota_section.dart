import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/person.dart';
import '../../persons/providers/person_providers.dart';
import '../providers/quota_providers.dart';
import 'participation_editor.dart';
import 'person_payment_summary.dart';
import '../providers/allocation_providers.dart';

class PersonQuotaSection extends ConsumerStatefulWidget {
  const PersonQuotaSection({
    super.key,
    required this.person,
    required this.currency,
  });
  final Person person;
  final String currency;
  @override
  ConsumerState<PersonQuotaSection> createState() => _PersonQuotaSectionState();
}

class _PersonQuotaSectionState extends ConsumerState<PersonQuotaSection> {
  late int _year;
  @override
  void initState() {
    super.initState();
    _year = ref.read(quotaMonthProvider(widget.person.groupId)).year;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.person, id = p.groupId;
    final current = ref.watch(quotaMonthProvider(id));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sus meses en el grupo',
            style: AppTypography.of(context).headingSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Cuotas, pagos y etapas de participación. Las aportaciones se relacionan con meses expresamente, sin deducir pagos por su fecha.',
            style: AppTypography.of(context).bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          PersonPaymentSummary(
            groupId: id,
            personId: p.id,
            currency: widget.currency,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppDropdown<int>(
            label: 'Año',
            value: _year,
            options: {
              for (
                var y = 2000;
                y <= (current.year < 2100 ? current.year + 1 : 2100);
                y++
              )
                y: '$y',
            },
            onChanged: (y) {
              if (y != null) setState(() => _year = y);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          ref
              .watch(personQuotaYearProvider((id, p.id, _year)))
              .when(
                loading: () =>
                    const LoadingIndicator(label: 'Calculando meses…'),
                error: (e, _) => Column(
                  children: [
                    Text(failureMessage(e)),
                    AppButton(
                      label: 'Reintentar cuotas',
                      variant: AppButtonVariant.ghost,
                      onPressed: () {
                        ref.invalidate(quotaRulesProvider(id));
                        ref.invalidate(allocationsProvider((id, p.id)));
                        ref.invalidate(
                          participationPeriodsProvider((id, p.id)),
                        );
                      },
                    ),
                  ],
                ),
                data: (months) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (months.isEmpty)
                      Text(
                        'No hay meses configurados para este año.',
                        style: AppTypography.of(context).bodySmall,
                      ),
                    for (final row in months)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          '${row.month} · ${quotaPaymentLabel(row)}\n'
                          'Asignado: ${formatMoneyCents(row.allocatedCents, currency: widget.currency)} · '
                          'Esperado: ${row.expectation.expectedCents == null ? 'Sin determinar' : formatMoneyCents(row.expectation.expectedCents!, currency: widget.currency)}',
                          style: AppTypography.of(context).bodyMedium,
                        ),
                      ),
                  ],
                ),
              ),
          const Divider(height: AppSpacing.xl),
          ref
              .watch(participationPeriodsProvider((id, p.id)))
              .when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (periods) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final period in periods)
                      Text(
                        '${period.firstMonth} → ${period.lastMonthInclusive ?? 'En curso'}',
                        style: AppTypography.of(context).bodySmall,
                      ),
                    if (ref.watch(canManagePersonsProvider(id)))
                      AppButton(
                        label: p.isActive
                            ? (p.lastParticipationPeriodId == null
                                  ? 'Elegir primer mes'
                                  : 'Cerrar periodo e inactivar')
                            : 'Reactivar y elegir primer mes',
                        variant: AppButtonVariant.ghost,
                        leadingIcon: Icons.calendar_month_outlined,
                        onPressed: () => showParticipationEditor(
                          context,
                          ref,
                          p,
                          starting:
                              !p.isActive ||
                              p.lastParticipationPeriodId == null,
                        ),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
