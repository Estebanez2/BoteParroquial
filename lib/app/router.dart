import '../core/routing/app_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../design_system/design_system.dart';
import '../design_system/lab/motion_lab_screen.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/offline/presentation/daily_copies_screen.dart';
import '../features/offline/presentation/snapshot_browser_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/persons/presentation/persons_screen.dart';
import '../features/persons/presentation/person_trash_screen.dart';
import '../features/groups/presentation/group_members_screen.dart';
import '../features/groups/presentation/group_navigation_shell.dart';
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
import '../features/groups/presentation/participants_screen.dart';
import '../features/settings/presentation/appearance_screen.dart';

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
      appRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          if (motionLabEnabled)
            appRoute(
              path: 'testing/motion',
              builder: (_, _) => const MotionLabScreen(),
            ),
          appRoute(
            path: 'settings/appearance',
            builder: (c, s) => const AppearanceScreen(),
          ),
          appRoute(
            path: 'groups/new',
            motion: AppPageMotion.form,
            builder: (c, s) => const GroupEditorScreen(),
          ),
          ShellRoute(
            pageBuilder: (context, state, child) => AppMotionPage<void>(
              key: state.pageKey,
              motion: AppPageMotion.group,
              origin: state.extra is AppGroupOrigin
                  ? (state.extra as AppGroupOrigin).rect
                  : null,
              child: GroupNavigationShell(state: state, child: child),
            ),
            routes: [
              appRoute(
                path: 'groups/:groupId',
                motion: AppPageMotion.section,
                sectionIndex: 0,
                builder: (c, s) =>
                    DashboardScreen(groupId: s.pathParameters['groupId']!),
                routes: [
                  appRoute(
                    path: 'participants',
                    motion: AppPageMotion.section,
                    sectionIndex: 2,
                    builder: (c, s) => ParticipantsScreen(
                      groupId: s.pathParameters['groupId']!,
                    ),
                  ),
                  appRoute(
                    path: 'persons',
                    motion: AppPageMotion.section,
                    sectionIndex: 2,
                    builder: (c, s) =>
                        PersonsScreen(groupId: s.pathParameters['groupId']!),
                  ),
                  appRoute(
                    path: 'members',
                    motion: AppPageMotion.section,
                    sectionIndex: 2,
                    builder: (c, s) => GroupMembersScreen(
                      groupId: s.pathParameters['groupId']!,
                    ),
                  ),
                  appRoute(
                    path: 'reports',
                    motion: AppPageMotion.section,
                    sectionIndex: 3,
                    builder: (c, s) => EconomicReportScreen(
                      groupId: s.pathParameters['groupId']!,
                    ),
                  ),
                  appRoute(
                    path: 'movements',
                    motion: AppPageMotion.section,
                    sectionIndex: 1,
                    builder: (c, s) => MovementsScreen(
                      groupId: s.pathParameters['groupId']!,
                      focusId: s.uri.queryParameters['focus'],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      appRoute(
        path: '/offline',
        builder: (context, state) => const DailyCopiesScreen(),
      ),
      appRoute(
        path: '/offline/:day',
        builder: (context, state) =>
            SnapshotBrowserScreen(day: state.pathParameters['day']!),
      ),
      appRoute(
        path: '/join',
        motion: AppPageMotion.form,
        builder: (context, state) => const JoinGroupScreen(),
      ),
      appRoute(
        path: '/join/:code',
        motion: AppPageMotion.form,
        builder: (context, state) =>
            JoinGroupScreen(initialCode: state.pathParameters['code']),
      ),
      appRoute(
        path: '/profile',
        motion: AppPageMotion.form,
        builder: (context, state) => const ProfileScreen(),
      ),
      appRoute(
        path: '/account/delete',
        motion: AppPageMotion.form,
        builder: (context, state) => const AccountDeletionScreen(),
      ),
      appRoute(
        path: '/groups/:groupId/delete',
        motion: AppPageMotion.form,
        builder: (context, state) => GroupDeletionScreen(
          groupId: state.pathParameters['groupId']!,
          pendingName: state.uri.queryParameters['name'],
        ),
      ),
      appRoute(
        path: '/groups/:groupId/settings',
        motion: AppPageMotion.form,
        builder: (context, state) =>
            GroupEditorScreen(groupId: state.pathParameters['groupId']!),
      ),
      appRoute(
        path: '/groups/:groupId/invitations',
        builder: (context, state) =>
            GroupInvitationsScreen(groupId: state.pathParameters['groupId']!),
      ),
      appRoute(
        path: '/groups/:groupId/quotas',
        builder: (context, state) =>
            QuotaScreen(groupId: state.pathParameters['groupId']!),
      ),
      appRoute(
        path: '/groups/:groupId/notifications',
        builder: (context, state) =>
            NotificationsScreen(groupId: state.pathParameters['groupId']!),
      ),
      appRoute(
        path: '/groups/:groupId/transfer',
        motion: AppPageMotion.form,
        builder: (context, state) =>
            OwnershipTransferScreen(groupId: state.pathParameters['groupId']!),
      ),
      appRoute(
        path: '/groups/:groupId/audit',
        builder: (context, state) =>
            GroupAuditScreen(groupId: state.pathParameters['groupId']!),
      ),
      appRoute(
        path: '/groups/:groupId/persons/:personId',
        builder: (context, state) => PersonDetailsScreen(
          groupId: state.pathParameters['groupId']!,
          personId: state.pathParameters['personId']!,
        ),
      ),
      appRoute(
        path: '/groups/:groupId/trash',
        builder: (context, state) =>
            PersonTrashScreen(groupId: state.pathParameters['groupId']!),
      ),
      appRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      appRoute(
        path: '/groups/:groupId/movements/new',
        motion: AppPageMotion.form,
        builder: (context, state) => MovementEditorScreen(
          groupId: state.pathParameters['groupId']!,
          initialType: state.uri.queryParameters['type'] == 'withdrawal'
              ? MovementType.withdrawal
              : MovementType.income,
        ),
      ),
      appRoute(
        path: '/groups/:groupId/movements/:movementId/correct',
        motion: AppPageMotion.form,
        builder: (context, state) => MovementEditorScreen(
          groupId: state.pathParameters['groupId']!,
          originalId: state.pathParameters['movementId']!,
        ),
      ),
      appRoute(
        path: '/groups/:groupId/movements/:movementId/allocations',
        motion: AppPageMotion.form,
        builder: (context, state) => IncomeAllocationScreen(
          groupId: state.pathParameters['groupId']!,
          movementId: state.pathParameters['movementId']!,
        ),
      ),
      appRoute(
        path: '/groups/:groupId/movements/:movementId/cancel',
        motion: AppPageMotion.form,
        builder: (context, state) => MovementEditorScreen(
          groupId: state.pathParameters['groupId']!,
          originalId: state.pathParameters['movementId']!,
          cancel: true,
        ),
      ),
      appRoute(
        path: '/groups/:groupId/refunds/:incomeId',
        motion: AppPageMotion.form,
        builder: (context, state) => RefundEditorScreen(
          groupId: state.pathParameters['groupId']!,
          incomeId: state.pathParameters['incomeId']!,
          originalId: state.uri.queryParameters['original'],
        ),
      ),
      appRoute(
        path: '/loading',
        builder: (context, state) => const AppScaffold(
          child: AppSkeleton(
            layout: AppSkeletonLayout.groups,
            label: 'Restaurando sesión',
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
