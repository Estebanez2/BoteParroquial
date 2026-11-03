import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/design_system.dart';
import 'group_bottom_navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/platform/app_section_render_scope.dart';
import '../../../design_system/platform/group_motion_metrics.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/group_providers.dart';

/// One bar for all main group sections, also inside the isolated copy router.
class GroupNavigationShell extends ConsumerStatefulWidget {
  const GroupNavigationShell({
    super.key,
    required this.state,
    required this.child,
  });
  final GoRouterState state;
  final Widget child;

  @override
  ConsumerState<GroupNavigationShell> createState() =>
      _GroupNavigationShellState();
}

class _GroupNavigationShellState extends ConsumerState<GroupNavigationShell> {
  int _index(GoRouterState state) => switch (state.uri.pathSegments.last) {
    'movements' => 1,
    'participants' || 'persons' || 'members' => 2,
    'reports' => 3,
    _ => 0,
  };
  late int _from = _index(widget.state), _to = _from;
  final _metrics = GroupMotionMetrics();
  @override
  void didUpdateWidget(GroupNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.uri != widget.state.uri) {
      _from = _index(oldWidget.state);
      _to = _index(widget.state);
      _metrics.start(_from, _to, View.of(context).display.refreshRate);
    }
  }

  @override
  void dispose() {
    _metrics.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupId = widget.state.pathParameters['groupId']!;
    final uid = ref.watch(authStateProvider).asData?.value?.uid;
    final memberships = ref.watch(membershipsProvider);
    final member = ref.watch(currentMembershipProvider(groupId));
    final group = ref.watch(groupProvider(groupId));
    final route = ModalRoute.of(context);
    final canFreeze =
        uid != null &&
        !memberships.isLoading &&
        !memberships.hasError &&
        member != null &&
        !group.isLoading &&
        !group.hasError &&
        group.asData?.value != null;
    return AppNavigationHost(
      navigation: GroupBottomNavigation(
        key: ValueKey(groupId),
        groupId: groupId,
        selectedIndex: _to,
      ),
      child: AppSectionRenderScope(
        accessKey: (
          uid,
          groupId,
          memberships.isLoading,
          memberships.hasError,
          member?.role,
          member?.personId,
          member?.updatedAt,
          group.isLoading,
          group.hasError,
          group.asData?.value?.isActive,
        ),
        canFreeze: canFreeze,
        outerAnimations: [?route?.animation, ?route?.secondaryAnimation],
        child: AppSectionMotionScope(
          fromIndex: _from,
          toIndex: _to,
          child: widget.child,
        ),
      ),
    );
  }
}
