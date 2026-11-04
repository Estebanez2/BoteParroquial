import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/movement.dart';
import '../../../models/initial_quota_assignment.dart';
import '../../quotas/presentation/initial_quota_picker.dart';
import '../../groups/providers/group_providers.dart';
import '../../groups/presentation/group_sync_notice.dart';
import '../../persons/providers/person_providers.dart';
import '../providers/movement_providers.dart';
import 'movement_review_dialog.dart';

class MovementEditorScreen extends ConsumerWidget {
  const MovementEditorScreen({
    super.key,
    required this.groupId,
    this.originalId,
    this.cancel = false,
    this.initialType = MovementType.income,
  });
  final String groupId;
  final String? originalId;
  final bool cancel;
  final MovementType initialType;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(groupProvider(groupId));
    if (access.isLoading) {
      return const AppScaffold(
        child: LoadingIndicator(label: 'Comprobando acceso…'),
      );
    }
    if (access.hasError ||
        access.asData?.value == null ||
        !ref.watch(canManageMovementsProvider(groupId))) {
      return AppScaffold(
        child: EmptyState(
          icon: Icons.lock_outline,
          title: 'No puedes gestionar movimientos',
          description: access.hasError
              ? failureMessage(access.error!)
              : 'Necesitas permisos administrativos en este grupo.',
          actionLabel: 'Volver al grupo',
          onAction: () => context.go('/groups/$groupId'),
        ),
      );
    }
    if (originalId == null) {
      return MovementEditorForm(groupId: groupId, initialType: initialType);
    }
    return ref
        .watch(movementsProvider(groupId))
        .when(
          skipLoadingOnReload: false,
          skipLoadingOnRefresh: false,
          loading: () => const AppScaffold(
            child: LoadingIndicator(label: 'Abriendo movimiento…'),
          ),
          error: (error, _) => AppScaffold(
            child: EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'No pudimos abrirlo',
              description: failureMessage(error),
              actionLabel: 'Volver al historial',
              onAction: () => context.go('/groups/$groupId/movements'),
            ),
          ),
          data: (movements) {
            Movement? original;
            for (final movement in movements) {
              if (movement.id == originalId) original = movement;
            }
            if (original == null) {
              return AppScaffold(
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Movimiento no disponible',
                  description: 'Vuelve al historial para actualizarlo.',
                  actionLabel: 'Volver al historial',
                  onAction: () => context.go('/groups/$groupId/movements'),
                ),
              );
            }
            return MovementEditorForm(
              key: ValueKey('$groupId/$originalId/$cancel'),
              groupId: groupId,
              original: original,
              cancel: cancel,
            );
          },
        );
  }
}

class MovementEditorForm extends ConsumerStatefulWidget {
  const MovementEditorForm({
    super.key,
    required this.groupId,
    this.original,
    this.cancel = false,
    this.initialType = MovementType.income,
  });
  final String groupId;
  final Movement? original;
  final bool cancel;
  final MovementType initialType;
  @override
  ConsumerState<MovementEditorForm> createState() => _MovementEditorFormState();
}

class _MovementEditorFormState extends ConsumerState<MovementEditorForm> {
  final _form = GlobalKey<FormState>();
  final _guard = GlobalKey<AppFormGuardState>();
  late String _initialAmount, _initialDescription;
  late DateTime _initialDate;
  late final Movement? _original;
  late final String _draftId;
  late final TextEditingController _amount, _description;
  final _reason = TextEditingController();
  late MovementType _type;
  late DateTime _date;
  String? _personId;
  int? _cents;
  String? _validation;
  bool _submitting = false;
  InitialQuotaAssignment? _initialQuota;

  Future<void> _pickQuota(String currency) async {
    if (_personId == null || (_cents ?? 0) <= 0) {
      AppSnackbar.show(
        context,
        'Indica primero la persona y el importe del ingreso.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final person = _personId!;
    final assignment = await AppBottomSheet.show<InitialQuotaAssignment>(
      context,
      title: 'Qué cuota paga este ingreso',
      builder: (_) => InitialQuotaPicker(
        groupId: widget.groupId,
        personId: person,
        incomeCents: _cents!,
        currency: currency,
        initial: _initialQuota,
      ),
    );
    if (mounted &&
        _personId == person &&
        _type == MovementType.income &&
        assignment != null) {
      setState(() => _initialQuota = assignment);
    }
  }

  @override
  void initState() {
    super.initState();
    _original = widget.original;
    _draftId = ref
        .read(movementControllerProvider(widget.groupId).notifier)
        .startDraft();
    final input = _original?.input;
    _type = input?.type ?? widget.initialType;
    _date =
        input?.occurredAt ??
        ref.read(movementControllerProvider(widget.groupId).notifier).today();
    _personId = input?.personId;
    _cents = input?.amountCents;
    _amount = TextEditingController(
      text: _cents == null
          ? ''
          : '${_cents! ~/ 100},${(_cents! % 100).toString().padLeft(2, '0')}',
    );
    _description = TextEditingController(text: input?.description);
    _initialAmount = _amount.text;
    _initialDescription = _description.text;
    _initialDate = _date;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _reason.dispose();
    super.dispose();
  }

  bool _validateDraft() {
    if (!(_form.currentState?.validate() ?? false)) return false;
    final controller = ref.read(
      movementControllerProvider(widget.groupId).notifier,
    );
    final input = MovementInput(
      type: _type,
      amountCents: _cents ?? 0,
      occurredAt: _date,
      description: _description.text,
      personId: _personId,
    );
    final error = widget.cancel
        ? controller.validateReason(_reason.text)
        : controller.validateInput(input) ??
              (_original == null
                  ? null
                  : controller.validateReason(_reason.text)) ??
              controller.validateInitialQuota(input, _initialQuota);
    setState(() => _validation = error);
    return error == null;
  }

  Future<void> _submit(String currency) async {
    if (_submitting || !_validateDraft()) return;
    final controller = ref.read(
      movementControllerProvider(widget.groupId).notifier,
    );
    final input = MovementInput(
      type: _type,
      amountCents: _cents ?? 0,
      occurredAt: _date,
      description: _description.text,
      personId: _personId,
    );
    setState(() => _submitting = true);
    try {
      final actor = controller.currentActor();
      final review = await controller.review(
        widget.cancel ? null : input,
        original: _original,
        cancel: widget.cancel,
        reason: _reason.text,
        operationId: _draftId,
      );
      if (!mounted || review == null) return;
      final confirmed = await confirmMovementReview(context, review, currency);
      if (!mounted || !confirmed) return;
      if (_initialQuota != null) {
        final quotaConfirmed = await AppDialog.show(
          context,
          title: 'Guardar ingreso y cuota',
          description:
              'Ingreso: ${formatMoneyCents(input.amountCents, currency: currency)}.\nCuota ${_initialQuota!.month}: ${formatMoneyCents(_initialQuota!.amountCents, currency: currency)}.\nRecibido sin asignar: ${formatMoneyCents(input.amountCents - _initialQuota!.amountCents, currency: currency)}.\n\nSe guardarán juntos. No se crea otro ingreso.',
          confirmLabel: 'Guardar ambos',
        );
        if (!mounted || !quotaConfirmed) return;
      }
      if (!widget.cancel && _original?.input.type == MovementType.income) {
        final reviewed = await AppDialog.show(
          context,
          title: 'Revisar el reparto tras corregir',
          description:
              'Si el original tenía meses asignados, dejarán de contar como pagos y se conservarán en su historial. El ingreso sustituto empezará sin reparto; tendrás que revisar sus meses expresamente.',
          confirmLabel: 'Continuar con la corrección',
          variant: AppDialogVariant.warning,
        );
        if (!mounted || !reviewed) return;
      }
      if (widget.cancel) {
        final confirmedCancel = await AppDialog.show(
          context,
          title: '¿Anular este movimiento?',
          description: _original?.input.refund != null
              ? 'La retirada dejará de contar en el saldo y se restaurarán conjuntamente las cuotas y el crédito de esta devolución. El historial se conserva.'
              : 'Se conservará el original con su motivo de anulación y dejará de contar en el saldo. Sus asignaciones a meses también dejarán de contar como pagos; se conservará su historial.',
          confirmLabel: 'Anular movimiento',
          variant: AppDialogVariant.warning,
        );
        if (!mounted || !confirmedCancel) return;
      }
      if (!widget.cancel && _original?.input.refund != null) {
        final confirmed = await AppDialog.show(
          context,
          title: 'Convertir en movimiento normal',
          description:
              'Esta corrección restaurará las cuotas y el crédito devueltos por el original. El movimiento sustituto contará en el bote sin modificar cuotas automáticamente.',
          confirmLabel: 'Confirmar conversión',
          variant: AppDialogVariant.warning,
        );
        if (!mounted || !confirmed) return;
      }
      final saved = widget.cancel
          ? await controller.cancel(
              _original!,
              _reason.text,
              expectedActorUid: actor,
            )
          : await controller.save(
              _draftId,
              input,
              original: _original,
              reason: _original == null ? null : _reason.text,
              expectedActorUid: actor,
              initialQuota: _initialQuota,
            );
      if (!mounted || !saved) return;
      AppSoundScope.emit(context, UiSound.success);
      _guard.currentState?.saved();
      context.go('/groups/${widget.groupId}/movements');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupId = widget.groupId;
    ref.listen(movementControllerProvider(groupId), (previous, next) {
      if (next.hasError && next.error != previous?.error) {
        AppSoundScope.emit(context, UiSound.warning);
      }
    });
    final state = ref.watch(movementControllerProvider(groupId));
    final group = ref.watch(groupProvider(groupId)).asData?.value;
    final people = ref.watch(personsProvider(groupId));
    final controller = ref.read(movementControllerProvider(groupId).notifier);
    final type = AppTypography.of(context);
    final title = widget.cancel
        ? 'Anular movimiento'
        : _original == null
        ? 'Nuevo movimiento'
        : 'Corregir movimiento';
    final allowed = ref.watch(canManageMovementsProvider(groupId));
    final busy = _submitting || state.isLoading;
    return AppFormGuard(
      key: _guard,
      busy: busy,
      changes: Listenable.merge([_amount, _description, _reason]),
      isDirty: () =>
          _amount.text != _initialAmount ||
          _description.text != _initialDescription ||
          _reason.text.isNotEmpty ||
          _date != _initialDate ||
          _type != (_original?.input.type ?? widget.initialType) ||
          _personId != _original?.input.personId ||
          _initialQuota != null,
      child: AppScaffold(
        maxWidth: AppSpacing.readingMax,
        appBar: AppTopBar(
          title: title,
          leading: AppIconButton(
            icon: Icons.arrow_back_rounded,
            label: 'Volver al historial',
            onPressed: busy
                ? null
                : () => _guard.currentState?.requestExit(
                    () => context.go('/groups/$groupId/movements'),
                  ),
          ),
        ),
        child: !allowed || group == null
            ? const EmptyState(
                icon: Icons.lock_outline,
                title: 'Acceso no disponible',
                description: 'Tu permiso en este grupo ha cambiado.',
              )
            : _original != null && _original.status != MovementStatus.active
            ? const EmptyState(
                icon: Icons.history_rounded,
                title: 'El original está conservado',
                description:
                    'Solo se pueden corregir o anular movimientos activos.',
              )
            : Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GroupSyncNotice(groupId: groupId),
                    if (widget.cancel) ...[
                      Text(
                        'El movimiento original y su motivo quedarán conservados.',
                        style: type.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (_original != null) ...[
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ORIGINAL CONSERVADO', style: type.labelSmall),
                            const SizedBox(height: AppSpacing.sm),
                            MoneyText(
                              _original.input.amountCents,
                              currency: group.currency,
                              variant:
                                  _original.input.type == MovementType.income
                                  ? MoneyTextVariant.income
                                  : MoneyTextVariant.withdrawal,
                            ),
                            Text(
                              _original.input.description.isEmpty
                                  ? 'Sin descripción'
                                  : _original.input.description,
                              style: type.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    if (!widget.cancel) ...[
                      AppChoiceBar<MovementType>(
                        value: _type,
                        options: const {
                          MovementType.income: 'Ingreso',
                          MovementType.withdrawal: 'Retirada',
                        },
                        enabled: !busy,
                        onChanged: (value) => setState(() {
                          _type = value;
                          if (value != MovementType.income) {
                            _initialQuota = null;
                          }
                        }),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppMoneyField(
                        currency: group.currency,
                        controller: _amount,
                        prominent: false,
                        enabled: !busy,
                        onChangedCents: (value) =>
                            setState(() => _cents = value),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      people.when(
                        skipLoadingOnRefresh: false,
                        skipLoadingOnReload: false,
                        loading: () =>
                            const LoadingIndicator(label: 'Cargando personas…'),
                        error: (error, _) => EmptyState(
                          icon: Icons.cloud_off_outlined,
                          title: 'No se pudieron cargar las personas',
                          description: failureMessage(error),
                          actionLabel: 'Reintentar personas',
                          onAction: () =>
                              ref.invalidate(personsProvider(groupId)),
                        ),
                        data: (persons) => AppDropdown<String>(
                          label: _type == MovementType.income
                              ? 'Persona del ingreso'
                              : 'Persona o grupo',
                          value: _personId ?? '',
                          enabled: !busy,
                          options: {
                            '': _type == MovementType.income
                                ? 'Selecciona una persona'
                                : 'El grupo (retirada general)',
                            for (final person in persons)
                              person.id:
                                  '${person.displayName}${person.isActive ? '' : ' · Inactiva'}',
                          },
                          onChanged: (value) => setState(() {
                            _personId = value == null || value.isEmpty
                                ? null
                                : value;
                            _initialQuota = null;
                          }),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppDateField(
                        label: 'Fecha efectiva',
                        lastDate: controller.today(),
                        value: _date,
                        onChanged: (value) => setState(() => _date = value),
                        enabled: !busy,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: _type == MovementType.income
                            ? 'Descripción (opcional)'
                            : 'Motivo de la retirada',
                        controller: _description,
                        icon: Icons.description_outlined,
                        enabled: !busy,
                      ),
                      if (_original == null &&
                          _type == MovementType.income) ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: _initialQuota == null
                                    ? 'Elegir cuota (opcional)'
                                    : 'Cuota ${_initialQuota!.month} · ${formatMoneyCents(_initialQuota!.amountCents, currency: group.currency)}',
                                leadingIcon: Icons.calendar_month_outlined,
                                size: AppButtonSize.compact,
                                variant: AppButtonVariant.outline,
                                onPressed: busy
                                    ? null
                                    : () => _pickQuota(group.currency),
                              ),
                            ),
                            if (_initialQuota != null)
                              AppIconButton(
                                icon: Icons.close_rounded,
                                label: 'Dejar todo sin asignar',
                                onPressed: busy
                                    ? null
                                    : () =>
                                          setState(() => _initialQuota = null),
                              ),
                          ],
                        ),
                      ],
                    ],
                    if (_original != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: widget.cancel
                            ? 'Motivo de la anulación'
                            : 'Motivo de la corrección',
                        controller: _reason,
                        validator: controller.validateReason,
                        enabled: !busy,
                      ),
                    ],
                    if (_validation != null || state.hasError) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        _validation ?? failureMessage(state.error!),
                        style: type.bodyMedium.copyWith(
                          color: AppColors.of(context).danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    AppButton(
                      label: widget.cancel
                          ? 'Revisar anulación'
                          : 'Revisar y guardar',
                      leadingIcon: Icons.check_rounded,
                      trailingIcon: Icons.chevron_right_rounded,
                      validate: _validateDraft,
                      fullWidth: true,
                      loading: state.isLoading,
                      onPressed: busy || people.isLoading || people.hasError
                          ? null
                          : () => _submit(group.currency),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
      ),
    );
  }
}
