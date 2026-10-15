import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/pending_movement.dart';
import '../../../models/movement.dart';
import '../providers/movement_providers.dart';
import 'movement_review_dialog.dart';

class PendingMovementCard extends ConsumerStatefulWidget {
  const PendingMovementCard({
    super.key,
    required this.groupId,
    required this.currency,
  });
  final String groupId, currency;
  @override
  ConsumerState<PendingMovementCard> createState() =>
      _PendingMovementCardState();
}

class _PendingMovementCardState extends ConsumerState<PendingMovementCard> {
  bool _busy = false;
  Future<void> _discard(PendingMovement submission) async {
    final confirmed = await AppDialog.show(
      context,
      title: '¿Has revisado el historial?',
      description:
          'Se descartará solo el intento guardado en este móvil. No se borrará ni anulará ningún movimiento. Descartarlo no detiene una solicitud que ya estuviera en curso: comprueba el historial antes de registrar otra vez el dinero.',
      confirmLabel: 'He revisado: descartar intento',
      variant: AppDialogVariant.warning,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(movementControllerProvider(widget.groupId).notifier)
          .discardPending(submission);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recover(PendingMovement submission) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final controller = ref.read(
        movementControllerProvider(widget.groupId).notifier,
      );
      final resolved = await controller.checkPending(submission);
      if (!mounted || resolved == null || resolved) return;
      final review = await controller.review(
        submission.cancel ? null : submission.input,
        original: submission.original,
        cancel: submission.cancel,
        reason: submission.reason,
        operationId: submission.id,
      );
      if (!mounted || review == null) return;
      if (!await confirmMovementReview(context, review, widget.currency) ||
          !mounted) {
        return;
      }
      final confirmed = await AppDialog.show(
        context,
        title: submission.cancel
            ? '¿Reintentar la anulación pendiente?'
            : '¿Reintentar este envío?',
        description:
            'Se enviarán los mismos datos y el mismo identificador. No se creará un envío distinto.',
        confirmLabel: 'Reintentar el mismo envío',
      );
      if (!confirmed || !mounted) return;
      if (submission.cancel) {
        await controller.cancel(submission.original!, submission.reason!);
      } else {
        await controller.save(
          submission.id,
          submission.input,
          original: submission.original,
          reason: submission.reason,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingMovementProvider(widget.groupId));
    final state = ref.watch(movementControllerProvider(widget.groupId));
    final type = AppTypography.of(context);
    return pending.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.lg),
        child: Text('Comprobando envíos pendientes…'),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: EmptyState(
          icon: Icons.warning_amber_rounded,
          title: 'No pudimos recuperar el envío',
          description: failureMessage(error),
          actionLabel: 'Reintentar recuperación',
          onAction: () =>
              ref.invalidate(pendingMovementProvider(widget.groupId)),
        ),
      ),
      data: (submission) => submission == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppBadge(
                      'Envío pendiente de confirmar',
                      tone: AppTone.warning,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    MoneyText(
                      submission.input.amountCents,
                      currency: widget.currency,
                      variant: submission.input.type == MovementType.income
                          ? MoneyTextVariant.income
                          : MoneyTextVariant.withdrawal,
                    ),
                    Text(
                      '${submission.input.type == MovementType.income ? 'Ingreso' : 'Retirada'} · ${MaterialLocalizations.of(context).formatMediumDate(submission.input.occurredAt)}',
                      style: type.bodyMedium,
                    ),
                    Text(
                      ref
                          .watch(movementLabelsProvider(widget.groupId))
                          .person(submission.input.personId),
                      style: type.bodyMedium,
                    ),
                    Text(
                      submission.cancel
                          ? 'Anulación pendiente'
                          : submission.original == null
                          ? 'Registro pendiente'
                          : 'Corrección pendiente',
                      style: type.headingSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Conservamos este envío en el móvil. Comprueba su resultado antes de registrar otro; no se repetirá automáticamente.',
                      style: type.bodyMedium,
                    ),
                    if (submission.input.description.isNotEmpty)
                      Text(
                        submission.input.description,
                        style: type.bodyMedium,
                      ),
                    if (submission.reason != null)
                      Text(submission.reason!, style: type.bodyMedium),
                    if (state.hasError)
                      Text(
                        failureMessage(state.error!),
                        style: type.bodyMedium,
                      ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Comprobar y recuperar envío',
                      loading: state.isLoading,
                      onPressed:
                          _busy ||
                              state.isLoading ||
                              !ref.watch(
                                canManageMovementsProvider(widget.groupId),
                              )
                          ? null
                          : () => _recover(submission),
                    ),
                    AppButton(
                      label: 'Revisar historial',
                      variant: AppButtonVariant.ghost,
                      onPressed: _busy || state.isLoading
                          ? null
                          : () => context.go(
                              '/groups/${widget.groupId}/movements',
                            ),
                    ),
                    if (ref.watch(canManageMovementsProvider(widget.groupId)))
                      AppButton(
                        label: 'Descartar intento local',
                        variant: AppButtonVariant.ghost,
                        onPressed: _busy || state.isLoading
                            ? null
                            : () => _discard(submission),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
