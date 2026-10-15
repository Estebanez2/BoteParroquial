import 'dart:async';

import 'package:bote_parroquial/app/app.dart';
import 'package:bote_parroquial/app/router.dart';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/core/firebase/firebase_bootstrap.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/models/auth_user.dart';
import 'package:bote_parroquial/models/user_profile.dart';
import 'package:bote_parroquial/repositories/auth_repository.dart';
import 'package:bote_parroquial/repositories/user_profile_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const alice = AuthUser(
  uid: 'alice',
  email: 'alice@example.test',
  displayName: 'Alicia',
);
const bob = AuthUser(
  uid: 'bob',
  email: 'bob@example.test',
  displayName: 'Roberto',
);

class FakeApp extends Fake implements FirebaseApp {}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository([this.current]);
  AuthUser? current;
  final changes = StreamController<AuthUser?>.broadcast();
  int signInCalls = 0;
  int signOutCalls = 0;
  Future<AuthUser> Function()? signInAction;
  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield current;
    yield* changes.stream;
  }

  void emit(AuthUser? user) {
    current = user;
    changes.add(user);
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    signInCalls++;
    final user = await (signInAction?.call() ?? Future.value(alice));
    emit(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    emit(null);
  }
}

class FakeProfileRepository implements UserProfileRepository {
  final requests = <String>[];
  Object? failure;
  @override
  Future<UserProfile> ensureProfile(AuthUser user) async {
    requests.add(user.uid);
    final error = failure;
    if (error != null) throw error;
    return UserProfile(
      uid: user.uid,
      displayName: user.displayName ?? 'Usuario',
      email: user.email,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
  }
}

ProviderContainer containerFor(
  FakeAuthRepository auth,
  FakeProfileRepository profiles,
) => ProviderContainer(
  overrides: [
    firebaseStartupProvider.overrideWithValue(FirebaseStartup.ready(FakeApp())),
    authRepositoryProvider.overrideWithValue(auth),
    userProfileRepositoryProvider.overrideWithValue(profiles),
  ],
);

void main() {
  testWidgets('Login, perfil privado y logout protegen la navegación', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    final profiles = FakeProfileRepository();
    final container = containerFor(auth, profiles);
    addTearDown(() async {
      container.dispose();
      await auth.changes.close();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BoteParroquialApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/login',
    );
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Alicia'), findsOneWidget);
    expect(profiles.requests, ['alice']);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('alice@example.test'), findsNothing);
    container.read(routerProvider).go('/');
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/login',
    );
    expect(auth.signOutCalls, 1);
  });

  testWidgets('Restaura sesión y descarta el perfil al cambiar de cuenta', (
    tester,
  ) async {
    final auth = FakeAuthRepository(alice);
    final profiles = FakeProfileRepository();
    final container = containerFor(auth, profiles);
    addTearDown(() async {
      container.dispose();
      await auth.changes.close();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BoteParroquialApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hola, Alicia'), findsOneWidget);
    auth.emit(bob);
    await tester.pumpAndSettle();
    expect(find.text('Hola, Roberto'), findsOneWidget);
    expect(find.text('alice@example.test'), findsNothing);
    expect(profiles.requests.last, 'bob');
    expect(auth.signInCalls, 0);
  });

  testWidgets('Un fallo de perfil permite reintentar y cerrar sesión', (
    tester,
  ) async {
    final auth = FakeAuthRepository(alice);
    final profiles = FakeProfileRepository()
      ..failure = const AppFailure(
        FailureCode.permissionDenied,
        'Sin permisos de perfil.',
      );
    final container = containerFor(auth, profiles);
    addTearDown(() async {
      container.dispose();
      await auth.changes.close();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BoteParroquialApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sin permisos de perfil.'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
    profiles.failure = null;
    await tester.tap(find.text('Reintentar perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Alicia'), findsOneWidget);
    expect(profiles.requests.length, 2);
  });

  testWidgets('Bloquea envíos duplicados y cancelar Google no muestra error', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    final pending = Completer<AuthUser>();
    auth.signInAction = () => pending.future;
    final container = containerFor(auth, FakeProfileRepository());
    addTearDown(() async {
      container.dispose();
      await auth.changes.close();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BoteParroquialApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar con Google'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    final second = container.read(authControllerProvider.notifier).signIn();
    await second;
    expect(auth.signInCalls, 1);
    pending.completeError(
      const AppFailure(FailureCode.cancelled, 'Acceso cancelado.'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Acceso cancelado.'), findsNothing);
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(container.read(authControllerProvider).hasError, isFalse);
  });
}
