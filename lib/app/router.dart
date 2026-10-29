import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/offline/presentation/daily_copies_screen.dart';
import '../features/offline/presentation/snapshot_browser_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/persons/presentation/persons_screen.dart';
import '../features/persons/presentation/person_trash_screen.dart';
import '../features/groups/presentation/group_members_screen.dart';
import '../features/movements/presentation/movements_screen.dart';
import '../features/movements/presentation/movement_editor_screen.dart';
import '../models/movement.dart';
import '../features/groups/presentation/group_editor_screen.dart';
import '../features/groups/presentation/group_audit_screen.dart';
import '../features/groups/presentation/group_invitations_screen.dart';
import '../features/groups/presentation/join_group_screen.dart';
import '../features/groups/presentation/ownership_transfer_screen.dart';
import '../features/quotas/presentation/quota_screen.dart';
import '../features/quotas/presentation/income_allocation_screen.dart';
import '../features/quotas/presentation/refund_editor_screen.dart';
import '../features/reports/presentation/economic_report_screen.dart';
import '../features/persons/presentation/person_details_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/auth/presentation/account_deletion_screen.dart';
import '../features/groups/presentation/group_deletion_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../core/firebase/firebase_bootstrap.dart';
import '../core/routing/invitation_links.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (previous, next) => refresh.value++);
  ref.listen(firebaseStartupProvider, (previous, next) => refresh.value++);
  final router = GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      final invitation = InvitationLinks.fromRoute(state.uri);
      final suffix = invitation == null
          ? ''
          : '?invitation=${Uri.encodeQueryComponent(invitation.value)}';
      if (state.uri.hasAuthority && invitation == null) return '/';
      if (!ref.read(firebaseStartupProvider).isReady) {
        return path == '/login' ? null : '/login$suffix';
      }
      final session = ref.read(authStateProvider);
      if (session.isLoading) {
        return path == '/loading' ? null : '/loading$suffix';
      }
      if (session.hasError || session.asData?.value == null) {
        return path == '/login' ? null : '/login$suffix';
      }
      return path == '/login' || path == '/loading'
          ? invitation == null
                ? '/'
                : '/join/${invitation.value}'
          : null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/offline',
        builder: (context, state) => const DailyCopiesScreen(),
      ),
      GoRoute(
        path: '/offline/:day',
        builder: (context, state) =>
            SnapshotBrowserScreen(day: state.pathParameters['day']!),
      ),
      GoRoute(
        path: '/join',
        builder: (context, state) => const JoinGroupScreen(),
      ),
      GoRoute(
        path: '/join/:code',
        builder: (context, state) =>
            JoinGroupScreen(initialCode: state.pathParameters['code']),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/account/delete',
        builder: (context, state) => const AccountDeletionScreen(),
      ),
      GoRoute(
        path: '/groups/:groupId/delete',
        builder: (context, state) => GroupDeletionScreen(
          groupId: state.pathParameters['groupId']!,
          pendingName: state.uri.queryParameters['name'],
        ),
      ),
      GoRoute(
        path: '/groups/new',
        builder: (context, state) => const GroupEditorScreen(),
      ),
      GoRoute(
        path: '/groups/:groupId/settings',
        builder: (context, state) =>
            GroupEditorScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/groups/:groupId/invitations',
        builder: (context, state) =>
            GroupInvitationsScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/groups/:groupId/quotas',
        builder: (context, state) =>
            QuotaScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/groups/:groupId/notifications',
        builder: (context, state) =>
            NotificationsScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/groups/:groupId/transfer',
        builder: (context, state) =>
            OwnershipTransferScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/groups/:groupId/audit',
        builder: (context, state) =>
            GroupAuditScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/groups/:groupId/reports',
        builder: (context, state) =>
            EconomicReportScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/groups/:groupId/persons/:personId',
        builder: (context, state) => PersonDetailsScreen(
          groupId: state.pathParameters['groupId']!,
          personId: state.pathParameters['personId']!,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId',
        builder: (context, state) =>
            DashboardScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/groups/:groupId/persons',
        builder: (context, state) =>
            PersonsScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/groups/:groupId/trash',
        builder: (context, state) =>
            PersonTrashScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/groups/:groupId/members',
        builder: (context, state) =>
            GroupMembersScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/groups/:groupId/movements',
        builder: (context, state) => MovementsScreen(
          groupId: state.pathParameters['groupId']!,
          focusId: state.uri.queryParameters['focus'],
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/movements/new',
        builder: (context, state) => MovementEditorScreen(
          groupId: state.pathParameters['groupId']!,
          initialType: state.uri.queryParameters['type'] == 'withdrawal'
              ? MovementType.withdrawal
              : MovementType.income,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/movements/:movementId/correct',
        builder: (context, state) => MovementEditorScreen(
          groupId: state.pathParameters['groupId']!,
          originalId: state.pathParameters['movementId']!,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/movements/:movementId/allocations',
        builder: (context, state) => IncomeAllocationScreen(
          groupId: state.pathParameters['groupId']!,
          movementId: state.pathParameters['movementId']!,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/movements/:movementId/cancel',
        builder: (context, state) => MovementEditorScreen(
          groupId: state.pathParameters['groupId']!,
          originalId: state.pathParameters['movementId']!,
          cancel: true,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/refunds/:incomeId',
        builder: (context, state) => RefundEditorScreen(
          groupId: state.pathParameters['groupId']!,
          incomeId: state.pathParameters['incomeId']!,
          originalId: state.uri.queryParameters['original'],
        ),
      ),
      GoRoute(
        path: '/loading',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Restaurando sesión',
            ),
          ),
        ),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
