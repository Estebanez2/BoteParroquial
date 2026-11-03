import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/refund_source.dart';
import '../../../models/year_month.dart';
import '../../groups/presentation/group_access_body.dart';
import '../../movements/presentation/movement_review_dialog.dart';
import '../../movements/providers/movement_providers.dart';
import '../providers/refund_providers.dart';

class RefundEditorScreen extends ConsumerWidget {
  const RefundEditorScreen({
    super.key,
    required this.groupId,
    required this.incomeId,
    this.originalId,
  });
  final String groupId, incomeId;
  final String? originalId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    maxWidth: AppSpacing.readingMax,
    appBar: AppTopBar(
      title: originalId == null
          ? 'Devolver una aportación'
          : 'Corregir devolución',
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver al ingreso',
        onPressed: () =>
            context.go('/groups/$groupId/movements/$incomeId/allocations'),
      ),
    ),
    child: GroupAccessBody(
      groupId: groupId,
      builder: (group, _) => !ref.watch(canManageMovementsProvider(groupId))
          ? const EmptyState(
              icon: Icons.lock_outline,
              title: 'No puedes registrar devoluciones',
              description: 'Necesitas permisos para gestionar movimientos.',
            )
          : _RefundSourceBody(
              key: ValueKey('$groupId/$incomeId/$originalId'),
              groupId: groupId,
              incomeId: incomeId,
              originalId: originalId,
              currency: group.currency,
            ),
    ),
  );
}

class _RefundSourceBody extends ConsumerStatefulWidget {
  const _RefundSourceBody({
    super.key,
    required this.groupId,
    required this.incomeId,
    required this.originalId,
    required this.currency,
  });
  final String groupId, incomeId, currency;
  final String? originalId;
  @override
  ConsumerState<_RefundSourceBody> createState() => _RefundSourceBodyState();
}

class _RefundSourceBodyState extends ConsumerState<_RefundSourceBody> {
  RefundSource? _lastSource;
  @override
  Widget build(BuildContext context) {
    final key = (widget.groupId, widget.incomeId, widget.originalId),
        value = ref.watch(
          refundSourceProvider((
            widget.groupId,
            widget.incomeId,
            widget.originalId,
          )),
        );
    if (!value.isLoading && !value.hasError) _lastSource = value.asData?.value;
    final source = _lastSource;
    if (source == null) {
      return value.hasError
          ? EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Devolución no disponible',
              description: failureMessage(value.error!),
              actionLabel: 'Actualizar',
              onAction: () => ref.invalidate(refundSourceProvider(key)),
            )
          : const LoadingIndicator(label: 'Reuniendo pagos disponibles…');
    }
    // Preserve the editor while the acknowledged correction removes its source
    // from the list of active refunds. Submission still reads the fresh provider.
    return RefundEditorForm(
      groupId: widget.groupId,
      currency: widget.currency,
      source: source,
      sourceReady: !value.isLoading && !value.hasError,
      sourceError: value.hasError ? failureMessage(value.error!) : null,
    );
  }
}

class RefundEditorForm extends ConsumerStatefulWidget {
  const RefundEditorForm({
    super.key,
    required this.groupId,
    required this.currency,
    required this.source,
    this.sourceReady = true,
    this.sourceError,
  });
  final String groupId, currency;
  final RefundSource source;
  final bool sourceReady;
  final String? sourceError;
  @override
  ConsumerState<RefundEditorForm> createState() => _RefundEditorFormState();
}

class _RefundEditorFormState extends ConsumerState<RefundEditorForm> {
  final _form = GlobalKey<FormState>();
  final _credit = TextEditingController(text: '0,00'),
      _description = TextEditingController(),
      _reason = TextEditingController();
  final _amounts = List.generate(4, (_) => TextEditingController(text: '0,00'));
  final _months = List<YearMonth?>.filled(4, null);
  late final String _draftId;
  late DateTime _date;
  int _slots = 1;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final controller = ref.read(
      movementControllerProvider(widget.groupId).notifier,
    );
    _draftId = controller.startDraft();
    _date = widget.source.original?.input.occurredAt ?? controller.today();
    _description.text = widget.source.original?.input.description ?? '';
  }

  @override
  void dispose() {
    for (final c in [_credit, _description, _reason, ..._amounts]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final source = widget.source;
      final controller = ref.read(
        movementControllerProvider(widget.groupId).notifier,
      );
      final actor = controller.currentActor();
      final input = ref
          .read(
            refundEditorProvider((
              widget.groupId,
              source.income.id,
              source.original?.id,
            )),
          )
          .prepare(
            selected: {
              for (var i = 0; i < _slots; i++)
                if (_months[i] != null)
                  _months[i]!: parseMoneyCents(_amounts[i].text),
            },
            unallocatedCents: parseMoneyCents(_credit.text),
            occurredAt: _date,
            description: _description.text,
          );
      final error =
          controller.validateInput(input) ??
          (source.original == null
              ? null
              : controller.validateReason(_reason.text));
      if (error != null) throw AppFailure(FailureCode.invalidData, error);
      final review = await controller.review(
        input,
        original: source.original,
        reason: _reason.text,
        operationId: _draftId,
      );
      if (!mounted || review == null) return;
      if (!await confirmMovementReview(context, review, widget.currency) ||
          !mounted) {
        return;
      }
      final plan = input.refund!;
      final detail = [
        for (final p in plan.parts)
          '${p.month}: ${formatMoneyCents(p.amountCents, currency: widget.currency)}',
        'Crédito sin asignar: ${formatMoneyCents(plan.unallocatedCents, currency: widget.currency)}',
      ].join('\n');
      final confirmed = await AppDialog.show(
        context,
        title: 'Confirmar devolución',
        description:
            'Total: ${formatMoneyCents(input.amountCents, currency: widget.currency)}\n\n$detail\n\n'
            '${source.original == null ? 'El importe saldrá del bote y dejará de pagar las cuotas elegidas.' : 'Se restaurará el reparto del original y se aplicará este sustituto.'} El ingreso y el historial se conservan.',
        confirmLabel: source.original == null
            ? 'Guardar devolución'
            : 'Guardar corrección',
        variant: AppDialogVariant.warning,
      );
      if (!mounted || !confirmed) return;
      final saved = await controller.save(
        _draftId,
        input,
        original: source.original,
        reason: source.original == null ? null : _reason.text,
        expectedActorUid: actor,
      );
      if (mounted && saved) {
        context.go('/groups/${widget.groupId}/movements?focus=$_draftId');
      }
    } catch (e) {
      if (mounted) setState(() => _error = failureMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.source,
        t = AppTypography.of(context),
        state = ref.watch(movementControllerProvider(widget.groupId));
    final busy = _busy || state.isLoading || !widget.sourceReady;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppReveal(
            child: AppHeroPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cada devolución, con su origen',
                    style: t.editorialTitle.copyWith(
                      color: AppColors.of(context).onHero,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    ref
                        .watch(movementLabelsProvider(widget.groupId))
                        .person(s.income.input.personId),
                    style: t.labelLarge.copyWith(
                      color: AppColors.of(context).onHero,
                    ),
                  ),
                  MoneyText(
                    s.income.input.amountCents,
                    currency: widget.currency,
                    color: AppColors.of(context).onHero,
                  ),
                  Text(
                    'Ingreso del ${MaterialLocalizations.of(context).formatMediumDate(s.income.input.occurredAt)}',
                    style: t.bodySmall.copyWith(
                      color: AppColors.of(context).onHero,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (s.original != null)
            AppCard(
              child: Text(
                'Revisa expresamente el nuevo reparto. Las cantidades empiezan en cero; lo devuelto por el original vuelve a estar disponible para esta corrección. Entre ambos repartos pueden intervenir hasta cuatro meses distintos.',
                style: t.bodyMedium,
              ),
            ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('De las cuotas pagadas', style: t.headingSmall),
                const SizedBox(height: AppSpacing.md),
                if (s.months.isEmpty)
                  Text(
                    'Este ingreso no tiene cuotas pagadas disponibles para devolver.',
                    style: t.bodyMedium,
                  ),
                if (s.months.isNotEmpty) ...[
                  for (var i = 0; i < _slots; i++) ...[
                    AppDropdown<YearMonth>(
                      label: 'Mes ${i + 1}',
                      value: _months[i],
                      enabled: !busy,
                      options: {
                        for (final m in s.months)
                          if (!_months.contains(m.month) ||
                              _months[i] == m.month)
                            m.month:
                                '${m.month} · ${formatMoneyCents(m.availableCents, currency: widget.currency)} disponibles',
                        if (_months[i] != null &&
                            !s.months.any((m) => m.month == _months[i]))
                          _months[i]!: '${_months[i]} · Ya no disponible',
                      },
                      onChanged: (v) => setState(() => _months[i] = v),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppMoneyField(
                      label: 'Cuánto devolver de este mes',
                      currency: widget.currency,
                      controller: _amounts[i],
                      enabled: !busy && _months[i] != null,
                    ),
                    if (_months[i] != null)
                      AppButton(
                        label: 'Quitar este mes',
                        variant: AppButtonVariant.ghost,
                        onPressed: busy
                            ? null
                            : () => setState(() {
                                _months[i] = null;
                                _amounts[i].text = '0,00';
                              }),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (_slots < 4)
                    AppButton(
                      label: 'Añadir otro mes',
                      variant: AppButtonVariant.ghost,
                      leadingIcon: Icons.add_rounded,
                      onPressed: busy ? null : () => setState(() => _slots++),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Del crédito sin asignar', style: t.headingSmall),
                Text(
                  '${formatMoneyCents(s.unallocatedCents, currency: widget.currency)} disponibles',
                  style: t.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                AppMoneyField(
                  label: 'Cuánto devolver de este crédito',
                  currency: widget.currency,
                  controller: _credit,
                  enabled: !busy,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              children: [
                AppDateField(
                  label: 'Fecha de la devolución',
                  value: _date,
                  firstDate: s.income.input.occurredAt,
                  lastDate: ref
                      .read(movementControllerProvider(widget.groupId).notifier)
                      .today(),
                  enabled: !busy,
                  onChanged: (d) => setState(() => _date = d),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Motivo de la devolución',
                  controller: _description,
                  enabled: !busy,
                ),
                if (s.original != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'Motivo de la corrección',
                    controller: _reason,
                    enabled: !busy,
                  ),
                ],
              ],
            ),
          ),
          if (_error != null ||
              state.hasError ||
              widget.sourceError != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              _error ?? widget.sourceError ?? failureMessage(state.error!),
              style: t.bodyMedium.copyWith(color: AppColors.of(context).danger),
            ),
            AppButton(
              label: 'Revisar historial y envíos pendientes',
              variant: AppButtonVariant.ghost,
              onPressed: _busy || state.isLoading
                  ? null
                  : () => context.go('/groups/${widget.groupId}/movements'),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Revisar devolución',
            validate: () => _form.currentState?.validate() ?? false,
            leadingIcon: Icons.assignment_return_outlined,
            loading: _busy || state.isLoading,
            onPressed: busy ? null : _save,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
