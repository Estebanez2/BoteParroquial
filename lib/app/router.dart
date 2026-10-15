import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/groups/presentation/group_screen.dart';
import '../core/firebase/firebase_bootstrap.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (previous, next) => refresh.value++);
  ref.listen(firebaseStartupProvider, (previous, next) => refresh.value++);
  final router = GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      if (!ref.read(firebaseStartupProvider).isReady) {
        return path == '/login' ? null : '/login';
      }
      final session = ref.read(authStateProvider);
      if (session.isLoading) return path == '/loading' ? null : '/loading';
      if (session.hasError || session.asData?.value == null) {
        return path == '/login' ? null : '/login';
      }
      return path == '/login' || path == '/loading' ? '/' : null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/groups/:groupId',
        builder: (context, state) =>
            GroupScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
