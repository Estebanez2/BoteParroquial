import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/design_system.dart';
import '../providers/group_sync_providers.dart';

class GroupSyncNotice extends ConsumerWidget {
  const GroupSyncNotice({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupServerConfirmedProvider(groupId));
    final unconfirmed =
        !state.isLoading && (state.hasError || state.asData?.value == false);
    return AppDelayedVisibility(
      key: ValueKey(groupId),
      visible: unconfirmed,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBadge(
                'Actualización pendiente',
                tone: AppTone.warning,
                icon: Icons.sync_problem_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Todavía no se ha confirmado la actualización de estos datos. Puedes consultar la información guardada; los movimientos necesitan confirmación del servidor.',
                style: AppTypography.of(context).bodyMedium,
              ),
              if (state.hasError)
                AppButton(
                  label: 'Comprobar actualización',
                  variant: AppButtonVariant.ghost,
                  onPressed: () =>
                      ref.invalidate(groupServerConfirmedProvider(groupId)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
