import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/movement.dart';
import '../../groups/providers/group_providers.dart';
import '../providers/movement_providers.dart';

class MovementsScreen extends ConsumerWidget {
  const MovementsScreen({super.key, required this.groupId, this.focusId});
  final String groupId;
  final String? focusId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(groupProvider(groupId));
    final type = AppTypography.of(context);
    final canManage = ref.watch(canManageMovementsProvider(groupId));
    final labels = ref.watch(movementLabelsProvider(groupId));
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
      child: access.isLoading
          ? const LoadingIndicator(label: 'Comprobando acceso…')
          : access.hasError || access.asData?.value == null
          ? EmptyState(
              icon: Icons.lock_outline,
              title: 'Espacio no disponible',
              description: access.hasError
                  ? failureMessage(access.error!)
                  : 'Necesitas una membresía activa.',
              actionLabel: 'Volver a mis grupos',
              onAction: () => context.go('/'),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppReveal(
                  child: Text(
                    'La memoria\nde lo compartido.',
                    style: type.displayLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Ingresos, retiradas y sus cambios. Cada original conserva su historia.',
                  style: type.bodyMedium,
                ),
                if (focusId != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Ver todo el historial',
                    variant: AppButtonVariant.outline,
                    onPressed: () => context.go('/groups/$groupId/movements'),
                  ),
                ],
                if (canManage && focusId == null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      AppButton(
                        label: 'Registrar ingreso',
                        leadingIcon: Icons.add_rounded,
                        onPressed: () => context.push(
                          '/groups/$groupId/movements/new?type=income',
                        ),
                      ),
                      AppButton(
                        label: 'Registrar retirada',
                        leadingIcon: Icons.north_east_rounded,
                        variant: AppButtonVariant.outline,
                        onPressed: () => context.push(
                          '/groups/$groupId/movements/new?type=withdrawal',
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.section),
                ref
                    .watch(movementHistoryProvider((groupId, focusId)))
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
                        onAction: () =>
                            ref.invalidate(movementsProvider(groupId)),
                      ),
                      data: (movements) => movements.isEmpty
                          ? const EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'Todo empieza con un movimiento.',
                              description:
                                  'Todavía no hay ingresos ni retiradas en este grupo.',
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final movement in movements)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.lg,
                                    ),
                                    child: AppReveal(
                                      key: ValueKey(movement.id),
                                      child: AppCard(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              spacing: AppSpacing.sm,
                                              runSpacing: AppSpacing.sm,
                                              children: [
                                                AppBadge(
                                                  movement.input.type ==
                                                          MovementType.income
                                                      ? 'Ingreso'
                                                      : 'Retirada',
                                                  tone:
                                                      movement.input.type ==
                                                          MovementType.income
                                                      ? AppTone.success
                                                      : AppTone.warning,
                                                ),
                                                AppBadge(
                                                  switch (movement.status) {
                                                    MovementStatus.active =>
                                                      'Activo',
                                                    MovementStatus.cancelled =>
                                                      'Anulado',
                                                    MovementStatus.corrected =>
                                                      'Corregido',
                                                  },
                                                  tone:
                                                      movement.status ==
                                                          MovementStatus.active
                                                      ? AppTone.primary
                                                      : AppTone.neutral,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            MoneyText(
                                              movement.input.amountCents,
                                              currency: access
                                                  .asData!
                                                  .value!
                                                  .currency,
                                              variant:
                                                  movement.input.type ==
                                                      MovementType.income
                                                  ? MoneyTextVariant.income
                                                  : MoneyTextVariant.withdrawal,
                                              size: MoneyTextSize.large,
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.sm,
                                            ),
                                            Text(
                                              labels.person(
                                                movement.input.personId,
                                              ),
                                              style: type.headingSmall,
                                            ),
                                            if (movement
                                                .input
                                                .description
                                                .isNotEmpty)
                                              Text(
                                                movement.input.description,
                                                style: type.bodyMedium,
                                              ),
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            Text(
                                              'Fecha efectiva: ${MaterialLocalizations.of(context).formatMediumDate(movement.input.occurredAt)}',
                                              style: type.bodySmall,
                                            ),
                                            Text(
                                              'Registrado por ${labels.author(movement.createdBy)} · ${MaterialLocalizations.of(context).formatMediumDate(movement.createdAt.toLocal())}',
                                              style: type.bodySmall,
                                            ),
                                            if (movement.cancellationReason !=
                                                null)
                                              Text(
                                                'Anulado: ${movement.cancellationReason}\nPor ${labels.author(movement.cancelledBy!)} · ${MaterialLocalizations.of(context).formatMediumDate(movement.cancelledAt!.toLocal())}',
                                                style: type.bodySmall,
                                              ),
                                            if (movement.correctionReason !=
                                                null)
                                              Text(
                                                'Corregido: ${movement.correctionReason}\nPor ${labels.author(movement.correctedBy!)} · ${MaterialLocalizations.of(context).formatMediumDate(movement.correctedAt!.toLocal())}',
                                                style: type.bodySmall,
                                              ),
                                            if (movement
                                                    .correctedByMovementId !=
                                                null)
                                              AppButton(
                                                label:
                                                    'Ver movimiento sustituto',
                                                variant: AppButtonVariant.ghost,
                                                onPressed: () => context.push(
                                                  '/groups/$groupId/movements?focus=${movement.correctedByMovementId}',
                                                ),
                                              ),
                                            if (movement
                                                    .correctionOfMovementId !=
                                                null)
                                              AppButton(
                                                label:
                                                    'Ver original conservado',
                                                variant: AppButtonVariant.ghost,
                                                onPressed: () => context.push(
                                                  '/groups/$groupId/movements?focus=${movement.correctionOfMovementId}',
                                                ),
                                              ),
                                            if (movement.status ==
                                                    MovementStatus.active &&
                                                canManage) ...[
                                              const SizedBox(
                                                height: AppSpacing.lg,
                                              ),
                                              Wrap(
                                                spacing: AppSpacing.sm,
                                                runSpacing: AppSpacing.sm,
                                                children: [
                                                  AppButton(
                                                    label: 'Corregir',
                                                    variant: AppButtonVariant
                                                        .outline,
                                                    size: AppButtonSize.compact,
                                                    onPressed: () => context.push(
                                                      '/groups/$groupId/movements/${movement.id}/correct',
                                                    ),
                                                  ),
                                                  AppButton(
                                                    label: 'Anular',
                                                    variant:
                                                        AppButtonVariant.ghost,
                                                    size: AppButtonSize.compact,
                                                    onPressed: () => context.push(
                                                      '/groups/$groupId/movements/${movement.id}/cancel',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
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
