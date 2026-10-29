import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/design_system.dart';
import '../../auth/providers/account_lifecycle_providers.dart';
import '../../groups/providers/group_deletion_providers.dart';

class PendingLifecyclePanel extends ConsumerWidget {
  const PendingLifecyclePanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(pendingGroupDeletionsProvider),
        closing = ref.watch(accountClosingProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (closing.asData?.value == true)
          AppButton(
            label: 'Reanudar la baja de mi cuenta',
            leadingIcon: Icons.person_remove_outlined,
            onPressed: () => context.push('/account/delete'),
          ),
        for (final task in rows.asData?.value ?? [])
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppButton(
              label: 'Reanudar eliminación: ${task.groupName}',
              variant: AppButtonVariant.outline,
              leadingIcon: Icons.delete_forever_outlined,
              onPressed: () => context.push(
                '/groups/${task.groupId}/delete?name=${Uri.encodeQueryComponent(task.groupName)}',
              ),
            ),
          ),
        if (rows.hasError || closing.hasError)
          Text(
            'No se pudieron comprobar las eliminaciones pendientes. Recupera la conexión y actualiza Inicio.',
            style: AppTypography.of(context).bodySmall,
          ),
      ],
    );
  }
}
