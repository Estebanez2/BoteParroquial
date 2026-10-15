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
    if (!state.isLoading && !state.hasError && state.asData?.value == true) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppBadge(
              'Actualización sin confirmar',
              tone: AppTone.warning,
              icon: Icons.cloud_off_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Los datos guardados pueden estar desactualizados o incompletos. Para confirmar movimientos necesitas conexión.',
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
    );
  }
}
