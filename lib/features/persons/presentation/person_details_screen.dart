import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/movement.dart';
import '../../../models/photo_target.dart';
import '../../groups/presentation/group_access_body.dart';
import '../../photos/presentation/photo_view.dart';
import '../../movements/providers/movement_providers.dart';
import '../../reports/providers/report_providers.dart';
import '../providers/person_providers.dart';
import 'person_editor.dart';
import '../../quotas/presentation/person_quota_section.dart';

class PersonDetailsScreen extends ConsumerWidget {
  const PersonDetailsScreen({
    super.key,
    required this.groupId,
    required this.personId,
  });
  final String groupId, personId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    maxWidth: AppSpacing.readingMax,
    appBar: AppTopBar(
      title: 'Ficha de persona',
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver a personas',
        onPressed: () => context.go('/groups/$groupId/persons'),
      ),
    ),
    child: GroupAccessBody(
      groupId: groupId,
      builder: (group, _) => ref
          .watch(personFinancialSummaryProvider((groupId, personId)))
          .when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () =>
                const LoadingIndicator(label: 'Preparando la ficha…'),
            error: (error, _) => EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Ficha no disponible',
              description: failureMessage(error),
              actionLabel: 'Reintentar',
              onAction: () {
                ref.invalidate(personsProvider(groupId));
                ref.invalidate(movementsProvider(groupId));
              },
            ),
            data: (summary) {
              final type = AppTypography.of(context),
                  locale = MaterialLocalizations.of(context);
              final person = summary.person;
              final labels = ref.watch(movementLabelsProvider(groupId));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppReveal(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: PhotoAvatar(
                              target: PhotoTarget.person(groupId, personId),
                              name: person.displayName,
                              size: AppAvatarSize.large,
                              interactive: true,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(person.displayName, style: type.editorialTitle),
                          const SizedBox(height: AppSpacing.sm),
                          AppBadge(
                            person.isActive ? 'Activa' : 'Inactiva',
                            tone: person.isActive
                                ? AppTone.success
                                : AppTone.neutral,
                          ),
                          if (person.notes != null)
                            Text(person.notes!, style: type.bodyMedium),
                          if (ref.watch(canManagePersonsProvider(groupId)))
                            AppButton(
                              label: 'Editar persona',
                              leadingIcon: Icons.edit_outlined,
                              variant: AppButtonVariant.ghost,
                              onPressed: () => showPersonEditor(
                                context,
                                ref,
                                groupId,
                                person: person,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppAdaptiveRow(
                    children: [
                      StatisticCard(
                        label: 'Total aportado',
                        value: formatMoneyCents(
                          summary.incomeCents,
                          currency: group.currency,
                        ),
                        icon: Icons.south_west_rounded,
                      ),
                      StatisticCard(
                        label: 'Total retirado',
                        value: formatMoneyCents(
                          summary.withdrawalCents,
                          currency: group.currency,
                        ),
                        icon: Icons.north_east_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  BalanceCard(
                    balanceCents: summary.netCents,
                    currency: group.currency,
                    caption:
                        'Aportación neta histórica · Solo movimientos activos',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PersonQuotaSection(
                    key: ValueKey(person.id),
                    person: person,
                    currency: group.currency,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Su historial económico', style: type.headingSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Incluye originales corregidos y anulados; no se suman de nuevo.',
                    style: type.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (summary.movements.isEmpty)
                    const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Una historia por empezar',
                      description:
                          'Esta persona todavía no tiene movimientos asociados.',
                    ),
                  for (final movement in summary.movements)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard(
                        variant: AppCardVariant.interactive,
                        onTap: () => context.push(
                          '/groups/$groupId/movements?focus=${movement.id}',
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              movement.input.description.isEmpty
                                  ? 'Ingreso'
                                  : movement.input.description,
                              style: type.labelLarge,
                            ),
                            MoneyText(
                              movement.input.amountCents,
                              currency: group.currency,
                              variant:
                                  movement.input.type == MovementType.income
                                  ? MoneyTextVariant.income
                                  : MoneyTextVariant.withdrawal,
                            ),
                            Text(
                              '${locale.formatMediumDate(movement.input.occurredAt)} · ${labels.author(movement.createdBy)}',
                              style: type.bodySmall,
                            ),
                            if (movement.status != MovementStatus.active)
                              AppBadge(
                                movement.status == MovementStatus.cancelled
                                    ? 'Anulado'
                                    : 'Corregido',
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
    ),
  );
}
