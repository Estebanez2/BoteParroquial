import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/quota_allocation.dart';
import '../../../models/quota_settlement.dart';
import '../../../models/year_month.dart';
import '../../groups/presentation/group_access_body.dart';
import '../../movements/providers/movement_providers.dart';
import '../providers/allocation_providers.dart';
import '../providers/quota_providers.dart';

class IncomeAllocationScreen extends ConsumerWidget {
  const IncomeAllocationScreen({
    super.key,
    required this.groupId,
    required this.movementId,
  });
  final String groupId, movementId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    maxWidth: AppSpacing.readingMax,
    appBar: AppTopBar(
      title: 'Cada aportación, su mes',
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver al ingreso',
        onPressed: () =>
            context.go('/groups/$groupId/movements?focus=$movementId'),
      ),
    ),
    child: GroupAccessBody(
      groupId: groupId,
      builder: (group, _) => ref
          .watch(incomeAllocationViewProvider((groupId, movementId)))
          .when(
            skipLoadingOnReload: false,
            skipLoadingOnRefresh: false,
            loading: () =>
                const LoadingIndicator(label: 'Preparando el reparto…'),
            error: (e, _) => EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Reparto no disponible',
              description: failureMessage(e),
              actionLabel: 'Actualizar',
              onAction: () {
                ref.invalidate(movementsProvider(groupId));
                ref.invalidate(
                  incomeAllocationViewProvider((groupId, movementId)),
                );
              },
            ),
            data: (view) => _AllocationBody(
              key: ValueKey('$groupId/$movementId'),
              groupId: groupId,
              currency: group.currency,
              view: view,
            ),
          ),
    ),
  );
}

class _AllocationBody extends ConsumerStatefulWidget {
  const _AllocationBody({
    super.key,
    required this.groupId,
    required this.currency,
    required this.view,
  });
  final String groupId, currency;
  final IncomeAllocationView view;
  @override
  ConsumerState<_AllocationBody> createState() => _AllocationBodyState();
}

class _AllocationBodyState extends ConsumerState<_AllocationBody> {
  late YearMonth _month;
  final _amount = TextEditingController();
  bool _busy = false;
  AllocationReview? _unconfirmed;
  @override
  void initState() {
    super.initState();
    _month = ref.read(quotaMonthProvider(widget.groupId));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _fill(YearMonth month, int cents) {
    setState(() {
      _month = month;
      _amount.text =
          '${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')}';
    });
  }

  Future<void> _save({AllocationReview? retry}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final controller = ref.read(
        allocationControllerProvider(widget.groupId).notifier,
      );
      final review =
          retry ??
          controller.review(
            widget.view.movement.id,
            _month,
            parseMoneyCents(_amount.text),
          );
      if (retry == null) {
        final warning = review.overpaymentCents > 0
            ? '\nEste mes quedará con un sobrepago de ${formatMoneyCents(review.overpaymentCents, currency: widget.currency)}.'
            : review.expectedCents == null
            ? '\nFalta una cuota para calcular este mes. El pago quedará registrado, pero su cumplimiento seguirá sin determinar.'
            : '';
        final confirmed = await AppDialog.show(
          context,
          title: 'Confirmar asignación',
          description:
              '${review.change.month}: ${formatMoneyCents(review.change.amountCents, currency: widget.currency)} de este ingreso. Es el total de este ingreso para ese mes; sustituye el reparto anterior de ese mes.$warning\n\nEl saldo del bote no cambia. Se conserva el historial del reparto.',
          confirmLabel: 'Guardar este mes',
          variant: warning.isEmpty
              ? AppDialogVariant.confirmation
              : AppDialogVariant.warning,
        );
        if (!mounted || !confirmed) return;
      }
      // Retain the same intent/ID when the response is uncertain; no blind resend.
      _unconfirmed = review;
      final saved = await controller.save(review);
      if (!mounted) return;
      if (saved) {
        setState(() => _unconfirmed = null);
        AppSnackbar.show(
          context,
          'Asignación confirmada.',
          variant: AppSnackbarVariant.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          failureMessage(e),
          variant: AppSnackbarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.view, id = widget.groupId, t = AppTypography.of(context);
    final heroColor = AppColors.of(context).onHero;
    final canEdit = v.canAllocate && ref.watch(canManageMovementsProvider(id));
    final state = ref.watch(allocationControllerProvider(id));
    final labels = ref.watch(movementLabelsProvider(id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppReveal(
          child: AppHeroPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labels.person(v.movement.input.personId),
                  style: t.editorialTitle.copyWith(color: heroColor),
                ),
                Text(
                  'Aportación recibida',
                  style: t.bodySmall.copyWith(color: heroColor),
                ),
                MoneyText(
                  v.movement.input.amountCents,
                  currency: widget.currency,
                  color: heroColor,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  v.canAllocate
                      ? 'Disponible para repartir'
                      : 'Reparto histórico · Ya no cuenta',
                  style: t.bodyMedium.copyWith(color: heroColor),
                ),
                MoneyText(
                  v.availableCents,
                  currency: widget.currency,
                  color: heroColor,
                ),
                Text(
                  'Reparto registrado: ${formatMoneyCents(v.assignedCents, currency: widget.currency)}',
                  style: t.bodySmall.copyWith(color: heroColor),
                ),
                if (v.refundedCents > 0)
                  Text(
                    'Devuelto: ${formatMoneyCents(v.refundedCents, currency: widget.currency)} · Sigue pagando cuotas: ${formatMoneyCents(v.paidCents, currency: widget.currency)}',
                    style: t.bodySmall.copyWith(color: heroColor),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!v.canAllocate)
          AppCard(
            child: Text(
              'El ingreso fue anulado o corregido. Sus asignaciones se conservan como historia y no pagan cuotas. El sustituto requiere revisar un nuevo reparto.',
              style: t.bodyMedium,
            ),
          ),
        if (canEdit) ...[
          AppButton(
            label: 'Devolver parte de esta aportación',
            leadingIcon: Icons.assignment_return_outlined,
            variant: AppButtonVariant.outline,
            onPressed: _busy || _unconfirmed != null
                ? null
                : () => context.push('/groups/$id/refunds/${v.movement.id}'),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!v.settlement.isComplete)
            AppCard(
              child: Text(
                'Completa los periodos y cuotas para obtener una propuesta y una deuda fiable. No se deducen pagos del importe ingresado.',
                style: t.bodyMedium,
              ),
            ),
          if (v.suggestions.isNotEmpty)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Un reparto para revisar', style: t.headingSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Primero los meses pendientes más antiguos, después hasta doce meses futuros. El resto queda sin asignar. Elige una propuesta y confirma cada mes; no se guarda automáticamente.',
                    style: t.bodySmall,
                  ),
                  for (final suggestion in v.suggestions)
                    AppButton(
                      label:
                          '${suggestion.month} · ${formatMoneyCents(suggestion.amountCents, currency: widget.currency)}',
                      variant: AppButtonVariant.ghost,
                      leadingIcon: Icons.calendar_month_outlined,
                      onPressed: _busy || _unconfirmed != null
                          ? null
                          : () =>
                                _fill(suggestion.month, suggestion.amountCents),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Tú eliges el mes', style: t.headingSmall),
                const SizedBox(height: AppSpacing.lg),
                AppMonthField(
                  value: _month.firstDayUtc,
                  enabled: !_busy && _unconfirmed == null,
                  onChanged: (d) =>
                      setState(() => _month = YearMonth.fromDate(d)),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppMoneyField(
                  label: 'Total de este ingreso para ese mes',
                  currency: widget.currency,
                  controller: _amount,
                  enabled: !_busy && _unconfirmed == null,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Usa 0 para liberar una asignación existente. No elimina el ingreso ni su historial. El mes debe pertenecer a una etapa de participación.',
                  style: t.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (state.hasError)
                  Text(failureMessage(state.error!), style: t.bodyMedium),
                if (_unconfirmed == null)
                  AppButton(
                    label: 'Revisar este mes',
                    leadingIcon: Icons.fact_check_outlined,
                    loading: _busy,
                    onPressed: _busy ? null : () => _save(),
                  ),
                if (_unconfirmed != null) ...[
                  Text(
                    'Comprueba el reparto mostrado antes de reintentar. Puedes cerrar esta pantalla y volver a abrirla para consultar el estado guardado.',
                    style: t.bodySmall,
                  ),
                  AppButton(
                    label: 'Comprobar o reintentar el mismo envío',
                    loading: _busy,
                    onPressed: _busy ? null : () => _save(retry: _unconfirmed),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text('El reparto de esta aportación', style: t.headingSmall),
        const SizedBox(height: AppSpacing.md),
        if (v.allocations.isEmpty)
          Text(
            'Sin meses asignados. Este ingreso cuenta en el bote, pero todavía no paga cuotas.',
            style: t.bodyMedium,
          ),
        for (final row in v.allocations)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${row.month} · Versión ${row.revision}',
                  style: t.labelLarge,
                ),
                MoneyText(row.amountCents, currency: widget.currency),
                if (v.settlement.refundedFor(v.movement.id, row.month) > 0)
                  Text(
                    'De este reparto se han devuelto ${formatMoneyCents(v.settlement.refundedFor(v.movement.id, row.month), currency: widget.currency)}. Solo el resto paga este mes.',
                    style: t.bodySmall,
                  ),
                if (canEdit)
                  AppButton(
                    label: 'Ajustar este mes',
                    variant: AppButtonVariant.ghost,
                    onPressed: _busy || _unconfirmed != null
                        ? null
                        : () => _fill(row.month, row.amountCents),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
