import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/design_system.dart';
import '../providers/movement_providers.dart';

/// The exact same actions on the group home and activity screen.
class MovementActions extends ConsumerWidget {
  const MovementActions({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(canManageMovementsProvider(groupId))) {
      return const SizedBox.shrink();
    }
    return AppAdaptiveRow(
      children: [
        AppNavigationTile(
          label: 'Registrar ingreso',
          icon: Icons.add_rounded,
          description: 'Añadir al bote',
          tone: AppTone.success,
          onTap: () =>
              context.push('/groups/$groupId/movements/new?type=income'),
        ),
        AppNavigationTile(
          label: 'Registrar retirada',
          icon: Icons.remove_rounded,
          description: 'Retirar del bote',
          tone: AppTone.danger,
          onTap: () =>
              context.push('/groups/$groupId/movements/new?type=withdrawal'),
        ),
      ],
    );
  }
}
