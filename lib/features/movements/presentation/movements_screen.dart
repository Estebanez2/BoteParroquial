import 'package:flutter/material.dart';
import '../../../models/photo_target.dart';
import '../../photos/presentation/photo_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/movement.dart';
import '../../groups/presentation/group_access_body.dart';
import '../providers/movement_providers.dart';
import 'pending_movement_card.dart';
import 'movement_history_controls.dart';

String _historyDayLabel(BuildContext context, DateTime date, DateTime today) {
  if (date == today) return 'Hoy';
  if (date == today.subtract(const Duration(days: 1))) return 'Ayer';
  return MaterialLocalizations.of(context).formatFullDate(date);
}

class MovementsScreen extends ConsumerWidget {
  const MovementsScreen({super.key, required this.groupId, this.focusId});
  final String groupId;
  final String? focusId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTypography.of(context);
    return AppScaffold(
      maxWidth: AppSpacing.readingMax,
      appBar: AppTopBar(
        title: 'Movimientos',
        leading: AppIconButton(
          icon: Icons.arrow_back_rounded,
          label: 'Volver al grupo',
          onPressed: () => context.go('/groups/$groupId'),
        ),
      ),
      child: GroupAccessBody(
        groupId: groupId,
        builder: (group, membership) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PendingMovementCard(groupId: groupId, currency: group.currency),
            Text('Historial de movimientos', style: t.editorialTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Todo el historial del grupo, por fecha efectiva. Abre un movimiento para ver sus detalles.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (focusId != null)
              AppButton(
                label: 'Ver todo el historial',
                variant: AppButtonVariant.outline,
                onPressed: () => context.go('/groups/$groupId/movements'),
              ),
            if (ref.watch(canManageMovementsProvider(groupId)) &&
                focusId == null)
              AppAdaptiveRow(
                children: [
                  AppButton(
                    label: 'Registrar ingreso',
                    fullWidth: true,
                    leadingIcon: Icons.add_rounded,
                    onPressed: () => context.push(
                      '/groups/$groupId/movements/new?type=income',
                    ),
                  ),
                  AppButton(
                    label: 'Registrar retirada',
                    fullWidth: true,
                    variant: AppButtonVariant.outline,
                    leadingIcon: Icons.north_east_rounded,
                    onPressed: () => context.push(
                      '/groups/$groupId/movements/new?type=withdrawal',
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.xl),
            if (focusId == null) ...[
              MovementHistoryControls(key: ValueKey(groupId), groupId: groupId),
              const SizedBox(height: AppSpacing.lg),
            ],
            ref
                .watch(movementDaysProvider((groupId, focusId)))
                .when(
                  skipLoadingOnRefresh: false,
                  skipLoadingOnReload: false,
                  loading: () =>
                      const LoadingIndicator(label: 'Cargando historial…'),
                  error: (error, _) => EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'El historial está a un reintento',
                    description: failureMessage(error),
                    actionLabel: 'Reintentar historial',
                    onAction: () => ref.invalidate(movementsProvider(groupId)),
                  ),
                  data: (days) => days.isEmpty
                      ? focusId != null
                            ? const EmptyState(
                                icon: Icons.search_off_rounded,
                                title: 'Movimiento no disponible',
                                description:
                                    'Vuelve al historial para consultar los movimientos del grupo.',
                              )
                            : ref
                                      .watch(movementFilterProvider(groupId))
                                      .criteriaCount !=
                                  0
                            ? EmptyState(
                                icon: Icons.search_off_rounded,
                                title: 'No hay coincidencias',
                                description:
                                    'Prueba con otra búsqueda o limpia los filtros para ver todo el historial.',
                                actionLabel: 'Mostrar todos los movimientos',
                                onAction: () => ref
                                    .read(
                                      movementFilterProvider(groupId).notifier,
                                    )
                                    .reset(),
                              )
                            : const EmptyState(
                                icon: Icons.receipt_long_outlined,
                                title: 'Todo empieza con un movimiento.',
                                description:
                                    'Todavía no hay ingresos ni retiradas en este grupo.',
                              )
                      : Column(
                          children: [
                            for (final day in days)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.lg,
                                ),
                                child: AppCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        _historyDayLabel(
                                          context,
                                          day.date,
                                          ref
                                              .read(
                                                movementControllerProvider(
                                                  groupId,
                                                ).notifier,
                                              )
                                              .today(),
                                        ),
                                        style: t.headingSmall,
                                      ),
                                      Text(
                                        '${day.movements.length} ${day.movements.length == 1 ? 'movimiento' : 'movimientos'}',
                                        style: t.bodySmall,
                                      ),
                                      const Divider(height: AppSpacing.lg),
                                      for (
                                        var i = 0;
                                        i < day.movements.length;
                                        i++
                                      ) ...[
                                        if (i != 0)
                                          const Divider(height: AppSpacing.sm),
                                        _MovementRow(
                                          key: ValueKey(day.movements[i].id),
                                          groupId: groupId,
                                          currency: group.currency,
                                          movement: day.movements[i],
                                          expanded: focusId != null,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
          ],
        ),
      ),
    );
  }
}

class _MovementRow extends ConsumerWidget {
  const _MovementRow({
    super.key,
    required this.groupId,
    required this.currency,
    required this.movement,
    required this.expanded,
  });
  final String groupId, currency;
  final Movement movement;
  final bool expanded;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTypography.of(context),
        labels = ref.watch(movementLabelsProvider(groupId));
    final l = MaterialLocalizations.of(context);
    final person = labels.person(movement.input.personId);
    return AppReveal(
      child: AppExpandableRow(
        expanded: expanded,
        leading: movement.input.personId == null
            ? AppAvatar(name: person)
            : PhotoAvatar(
                target: PhotoTarget.person(groupId, movement.input.personId!),
                name: person,
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppBadge(
                  movement.input.type == MovementType.income
                      ? 'Ingreso'
                      : movement.input.refund == null
                      ? 'Retirada'
                      : 'Devolución',
                  tone: movement.input.type == MovementType.income
                      ? AppTone.success
                      : AppTone.danger,
                ),
                if (movement.status != MovementStatus.active)
                  AppBadge(
                    movement.status == MovementStatus.cancelled
                        ? 'Anulado'
                        : 'Corregido',
                    tone: AppTone.neutral,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            MoneyText(
              movement.input.amountCents,
              currency: currency,
              variant: movement.input.type == MovementType.income
                  ? MoneyTextVariant.income
                  : MoneyTextVariant.withdrawal,
            ),
            Text(person, style: t.labelLarge),
            if (movement.input.description.isNotEmpty)
              Text(movement.input.description, style: t.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${labels.author(movement.createdBy)} · ${l.formatTimeOfDay(TimeOfDay.fromDateTime(movement.createdAt.toLocal()), alwaysUse24HourFormat: true)}',
              style: t.bodySmall,
            ),
          ],
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha efectiva: ${l.formatMediumDate(movement.input.occurredAt)}',
                  style: t.bodySmall,
                ),
                Text(
                  'Registrado por ${labels.author(movement.createdBy)} · ${l.formatMediumDate(movement.createdAt.toLocal())}',
                  style: t.bodySmall,
                ),
                if (movement.cancellationReason != null)
                  Text(
                    'Anulado: ${movement.cancellationReason}\nPor ${labels.author(movement.cancelledBy!)} · ${l.formatMediumDate(movement.cancelledAt!.toLocal())}',
                    style: t.bodySmall,
                  ),
                if (movement.correctionReason != null)
                  Text(
                    'Corregido: ${movement.correctionReason}\nPor ${labels.author(movement.correctedBy!)} · ${l.formatMediumDate(movement.correctedAt!.toLocal())}',
                    style: t.bodySmall,
                  ),
                if (movement.correctedByMovementId != null)
                  AppButton(
                    label: 'Ver movimiento sustituto',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => context.push(
                      '/groups/$groupId/movements?focus=${movement.correctedByMovementId}',
                    ),
                  ),
                if (movement.input.refund case final refund?) ...[
                  Text(
                    'Devolución · Crédito sin asignar: ${formatMoneyCents(refund.unallocatedCents, currency: currency)}',
                    style: t.bodySmall,
                  ),
                  for (final part in refund.parts)
                    Text(
                      '${part.month}: ${formatMoneyCents(part.amountCents, currency: currency)}',
                      style: t.bodySmall,
                    ),
                  AppButton(
                    label: 'Ver ingreso de origen',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => context.push(
                      '/groups/$groupId/movements?focus=${refund.incomeId}',
                    ),
                  ),
                ],
                if (movement.input.type == MovementType.income)
                  AppButton(
                    label: movement.status == MovementStatus.active
                        ? 'Repartir por meses'
                        : 'Ver reparto conservado',
                    variant: AppButtonVariant.ghost,
                    leadingIcon: Icons.calendar_month_outlined,
                    onPressed: () => context.push(
                      '/groups/$groupId/movements/${movement.id}/allocations',
                    ),
                  ),
                if (movement.correctionOfMovementId != null)
                  AppButton(
                    label: 'Ver original conservado',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => context.push(
                      '/groups/$groupId/movements?focus=${movement.correctionOfMovementId}',
                    ),
                  ),
                if (movement.status == MovementStatus.active &&
                    ref.watch(canManageMovementsProvider(groupId)))
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      AppButton(
                        label: 'Corregir',
                        variant: AppButtonVariant.outline,
                        size: AppButtonSize.compact,
                        onPressed: () => context.push(
                          movement.input.refund == null
                              ? '/groups/$groupId/movements/${movement.id}/correct'
                              : '/groups/$groupId/refunds/${movement.input.refund!.incomeId}?original=${movement.id}',
                        ),
                      ),
                      if (movement.input.refund != null)
                        AppButton(
                          label: 'Corregir como movimiento normal',
                          variant: AppButtonVariant.ghost,
                          size: AppButtonSize.compact,
                          onPressed: () => context.push(
                            '/groups/$groupId/movements/${movement.id}/correct',
                          ),
                        ),
                      AppButton(
                        label: 'Anular',
                        variant: AppButtonVariant.ghost,
                        size: AppButtonSize.compact,
                        onPressed: () => context.push(
                          '/groups/$groupId/movements/${movement.id}/cancel',
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
