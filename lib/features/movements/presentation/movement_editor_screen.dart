import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/movement.dart';
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
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit(String currency) async {
    if (_submitting || !(_form.currentState?.validate() ?? false)) return;
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
                  : controller.validateReason(_reason.text));
    setState(() => _validation = error);
    if (error != null) return;
    setState(() => _submitting = true);
    try {
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
      if (widget.cancel) {
        final confirmedCancel = await AppDialog.show(
          context,
          title: '¿Anular este movimiento?',
          description:
              'Se conservará el original con su motivo de anulación y dejará de contar en el saldo.',
          confirmLabel: 'Anular movimiento',
          variant: AppDialogVariant.warning,
        );
        if (!mounted || !confirmedCancel) return;
      }
      final saved = widget.cancel
          ? await controller.cancel(_original!, _reason.text)
          : await controller.save(
              _draftId,
              input,
              original: _original,
              reason: _original == null ? null : _reason.text,
            );
      if (!mounted || !saved) return;
      context.go('/groups/${widget.groupId}/movements');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupId = widget.groupId;
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
    return PopScope(
      canPop: !busy,
      child: AppScaffold(
        maxWidth: AppSpacing.readingMax,
        appBar: AppTopBar(
          title: title,
          leading: AppIconButton(
            icon: Icons.arrow_back_rounded,
            label: 'Volver al historial',
            onPressed: busy
                ? null
                : () => context.go('/groups/$groupId/movements'),
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
                    AppReveal(child: Text(title, style: type.editorialTitle)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.cancel
                          ? 'El movimiento original y su motivo quedarán conservados.'
                          : 'Registra un ingreso o una retirada en el fondo común de tu comunidad.',
                      style: type.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
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
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('TIPO DE MOVIMIENTO', style: type.labelSmall),
                            const SizedBox(height: AppSpacing.md),
                            AppChoiceBar<MovementType>(
                              value: _type,
                              options: const {
                                MovementType.income: 'Ingreso',
                                MovementType.withdrawal: 'Retirada',
                              },
                              enabled: !busy,
                              onChanged: (value) =>
                                  setState(() => _type = value),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Los ingresos aumentan el saldo del fondo. Las retiradas lo disminuyen.',
                              style: type.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        child: AppMoneyField(
                          currency: group.currency,
                          controller: _amount,
                          enabled: !busy,
                          onChangedCents: (value) => _cents = value,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        child: people.when(
                          skipLoadingOnRefresh: false,
                          skipLoadingOnReload: false,
                          loading: () => const LoadingIndicator(
                            label: 'Cargando personas…',
                          ),
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
                            onChanged: (value) => setState(
                              () => _personId = value == null || value.isEmpty
                                  ? null
                                  : value,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        child: AppDateField(
                          label: 'Fecha efectiva',
                          lastDate: controller.today(),
                          value: _date,
                          onChanged: (value) => setState(() => _date = value),
                          enabled: !busy,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        child: AppTextField(
                          label: _type == MovementType.income
                              ? 'Descripción (opcional)'
                              : 'Motivo de la retirada',
                          controller: _description,
                          icon: Icons.description_outlined,
                          enabled: !busy,
                        ),
                      ),
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
