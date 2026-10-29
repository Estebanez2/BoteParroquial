import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../design_system/design_system.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/groups/providers/group_providers.dart';
import '../features/notifications/providers/notification_providers.dart';
import '../features/offline/providers/daily_snapshot_providers.dart';

import 'router.dart';

class BoteParroquialApp extends ConsumerWidget {
  const BoteParroquialApp({super.key, this.themeMode = ThemeMode.dark});
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pushDeviceControllerProvider);
    ref.watch(dailyCopyControllerProvider);
    void openNotification() {
      final event = ref.read(notificationOpenProvider);
      final memberships = ref.read(membershipsProvider);
      if (event == null || memberships.isLoading || memberships.hasError) {
        return;
      }
      final uid = ref.read(authStateProvider).asData?.value?.uid;
      if (uid == event.recipientUid &&
          (memberships.asData?.value ?? []).any(
            (m) => m.uid == uid && m.groupId == event.groupId && m.isActive,
          )) {
        ref
            .read(routerProvider)
            .push(
              '/groups/${Uri.encodeComponent(event.groupId)}/notifications',
            );
      }
      ref.read(notificationOpenProvider.notifier).clear();
    }

    ref.listen(notificationOpenProvider, (_, _) => openNotification());
    ref.listen(membershipsProvider, (_, _) => openNotification());
    return _DailyCopyLifecycle(
      child: MaterialApp.router(
        title: 'BoteParroquial',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: ref.watch(routerProvider),
      ),
    );
  }
}

class _DailyCopyLifecycle extends ConsumerStatefulWidget {
  const _DailyCopyLifecycle({required this.child});
  final Widget child;
  @override
  ConsumerState<_DailyCopyLifecycle> createState() =>
      _DailyCopyLifecycleState();
}

class _DailyCopyLifecycleState extends ConsumerState<_DailyCopyLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref
        .read(dailyCopyControllerProvider.notifier)
        .foreground(state == AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
