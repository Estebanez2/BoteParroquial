import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/design_system.dart';
import '../providers/group_providers.dart';

/// Existing read screens, also valid inside the isolated copy router.
class GroupBottomNavigation extends ConsumerWidget {
  const GroupBottomNavigation({
    super.key,
    required this.groupId,
    required this.selectedIndex,
  });
  final String groupId;
  final int selectedIndex;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = ref.watch(membershipsProvider);
    if (memberships.isLoading ||
        memberships.hasError ||
        ref.watch(currentMembershipProvider(groupId)) == null) {
      return const SizedBox.shrink();
    }
    final base = '/groups/${Uri.encodeComponent(groupId)}';
    return AppBottomNavigation(
      items: const [
        AppNavigationItem(
          label: 'Inicio',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        AppNavigationItem(
          label: 'Actividad',
          icon: Icons.receipt_long_outlined,
        ),
        AppNavigationItem(
          label: 'Participantes',
          icon: Icons.people_outline,
          selectedIcon: Icons.people_rounded,
        ),
        AppNavigationItem(label: 'Informes', icon: Icons.bar_chart_rounded),
      ],
      selectedIndex: selectedIndex,
      onSelected: (index) {
        if (index == selectedIndex) return;
        context.go(
          [
            base,
            '$base/movements',
            '$base/participants',
            '$base/reports',
          ][index],
        );
      },
    );
  }
}
