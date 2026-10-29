import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:bote_parroquial/app/app.dart';
import 'package:bote_parroquial/app/router.dart';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/core/firebase/firebase_bootstrap.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_sync_providers.dart';
import 'package:bote_parroquial/features/notifications/providers/notification_providers.dart';
import 'package:bote_parroquial/features/notifications/providers/push_device_providers.dart';
import 'package:bote_parroquial/features/photos/providers/photo_providers.dart';
import 'package:bote_parroquial/models/group_notification.dart';
import 'package:bote_parroquial/repositories/auth_repository.dart';
import 'package:bote_parroquial/repositories/notification_repository.dart';
import 'package:bote_parroquial/repositories/push_device_repository.dart';
import 'package:bote_parroquial/services/auth_service.dart';
import 'package:bote_parroquial/services/file_push_registration_service.dart';
import 'package:bote_parroquial/services/notification_service.dart';
import 'auth_flow_test.dart' as auth;
import 'groups_test.dart' as groups;

class LocalRegistration implements PushRegistrationService {
  PushRegistration? value;
  @override
  Future<PushRegistration?> read() async => value;
  @override
  Future<void> write(PushRegistration registration) async {
    value = registration;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

class Messaging implements PushMessagingService {
  String? uid = 'alice';
  bool granted = true;
  int permissionRequests = 0, stops = 0;
  String currentToken = 'DEMO-long-device-token-one';
  final refresh = StreamController<void>.broadcast();
  final taps = StreamController<NotificationOpen>.broadcast();
  @override
  String? get currentUid => uid;
  @override
  String get platform => 'android';
  @override
  Future<bool> authorized({bool request = false}) async {
    if (request) permissionRequests++;
    return granted;
  }

  @override
  Future<String?> token() async => currentToken;
  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Stream<void> get tokenChanges => refresh.stream;
  @override
  Stream<NotificationOpen> get opened => taps.stream;
  @override
  Future<NotificationOpen?> initialOpen() async => null;
  Future<void> close() async {
    await refresh.close();
    await taps.close();
  }
}

class Notices implements NotificationService {
  bool offline = false, preference = true, leak = false;
  final devices = <String, String>{};
  final changes = StreamController<void>.broadcast();
  List<GroupNotification> items = [
    notice('one', 'alice'),
    notice('foreign', 'bob'),
  ];
  static GroupNotification notice(String id, String uid, {DateTime? readAt}) =>
      GroupNotification(
        id: id,
        groupId: 'a',
        recipientUid: uid,
        kind: GroupNotificationKind.quotaReminder,
        title: uid == 'alice' ? 'DEMO: tu recordatorio' : 'DEMO: aviso ajeno',
        body: 'Abre la app para ver el detalle.',
        createdAt: DateTime.utc(2026, 10, 24, 8),
        readAt: readAt,
      );
  @override
  Stream<List<GroupNotification>> watchInbox(
    String groupId,
    String uid,
  ) async* {
    List<GroupNotification> read() => items
        .where((n) => leak || n.groupId == groupId && n.recipientUid == uid)
        .toList();
    yield read();
    yield* changes.stream.map((_) => read());
  }

  @override
  Stream<bool> watchQuotaPushEnabled(String groupId, String uid) async* {
    yield preference;
    yield* changes.stream.map((_) => preference);
  }

  @override
  Future<void> setQuotaPushEnabled(
    String groupId,
    String uid,
    bool enabled,
  ) async {
    preference = enabled;
    changes.add(null);
  }

  @override
  Future<void> markRead(String groupId, String uid, String id) async {
    items = [
      for (final n in items)
        n.id == id && n.recipientUid == uid
            ? notice(id, uid, readAt: DateTime.utc(2026, 10, 24, 9))
            : n,
    ];
    changes.add(null);
  }

  @override
  Future<void> registerDevice(
    String uid,
    String token,
    String platform,
    List<String> oldIds,
  ) async {
    if (offline) {
      throw const AppFailure(FailureCode.network, 'DEMO sin conexión');
    }
    final id = sha256.convert(utf8.encode(token)).toString();
    for (final old in oldIds) {
      devices.remove('$uid/$old');
    }
    devices['$uid/$id'] = token;
  }

  @override
  Future<void> unregisterDevices(String uid, List<String> ids) async {
    if (offline) {
      throw const AppFailure(FailureCode.network, 'DEMO sin conexión');
    }
    for (final id in ids) {
      devices.remove('$uid/$id');
    }
  }
}

class SessionService extends auth.FakeAuthRepository implements AuthService {
  SessionService() : super(auth.alice);
}

void main() {
  test(
    'Consentimiento, registro incierto y logout bloqueado hasta retirar el dispositivo',
    () async {
      final native = Messaging(),
          cloud = Notices(),
          local = LocalRegistration(),
          session = SessionService();
      addTearDown(native.close);
      addTearDown(cloud.changes.close);
      addTearDown(session.changes.close);
      final devices = PushDeviceRepository(native, cloud, local);
      final account = DefaultAuthRepository(session, devices);
      expect(await devices.resume('alice'), false);
      expect(native.permissionRequests, 0);
      native.granted = false;
      await expectLater(devices.enable('alice'), throwsA(isA<AppFailure>()));
      expect(local.value, isNull);
      native.granted = true;
      cloud.offline = true;
      await expectLater(devices.enable('alice'), throwsA(isA<AppFailure>()));
      expect(local.value?.tokenIds, hasLength(1));
      await expectLater(account.signOut(), throwsA(isA<AppFailure>()));
      expect(session.signOutCalls, 0);
      expect(local.value, isNotNull);
      expect(local.value?.enabled, false);
      cloud.offline = false;
      expect(await devices.resume('alice'), false);
      expect(cloud.devices, isEmpty);
      expect(await devices.enable('alice'), true);
      expect(cloud.devices, hasLength(1));
      await account.signOut();
      expect(session.signOutCalls, 1);
      expect(cloud.devices, isEmpty);
      expect(local.value, isNull);
      expect(native.stops, 2);
    },
  );
  test(
    'Rotación conserva otros móviles; un cambio externo de cuenta invalida el registro anterior',
    () async {
      final native = Messaging(),
          cloud = Notices(),
          local = LocalRegistration();
      addTearDown(native.close);
      addTearDown(cloud.changes.close);
      final devices = PushDeviceRepository(native, cloud, local);
      cloud.devices['alice/another-device'] = 'DEMO-other';
      await devices.enable('alice');
      native.currentToken = 'DEMO-long-device-token-two';
      await devices.resume('alice');
      expect(cloud.devices, hasLength(2));
      expect(cloud.devices.values, contains('DEMO-other'));
      expect(
        cloud.devices.values,
        isNot(contains('DEMO-long-device-token-one')),
      );
      expect(local.value?.tokenIds, hasLength(1));
      native.uid = 'bob';
      expect(await devices.resume('bob'), false);
      expect(native.stops, 1);
      expect(local.value, isNull);
      expect(cloud.devices.keys.every((key) => key.startsWith('alice/')), true);
      expect(await devices.resume('bob'), false);
      expect(native.permissionRequests, 1);
      cloud.leak = true;
      await expectLater(
        NotificationRepository(cloud).watchInbox('a', 'alice').first,
        throwsA(isA<AppFailure>()),
      );
    },
  );
  test(
    'El registro local persiste la intención sin token y no ignora un archivo corrupto',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'bote-notification-test-',
      );
      addTearDown(() async {
        final root = Directory.systemTemp.absolute.path;
        if (!directory.absolute.path.startsWith(
          '$root${Platform.pathSeparator}',
        )) {
          throw StateError('Ruta ajena al temporal');
        }
        await directory.delete(recursive: true);
      });
      final service = FilePushRegistrationService(
        directory: () async => directory,
      );
      expect(await service.read(), isNull);
      final id = 'a' * 64;
      await service.write(PushRegistration(uid: 'alice', tokenIds: [id]));
      expect(
        (await FilePushRegistrationService(
          directory: () async => directory,
        ).read())?.uid,
        'alice',
      );
      final file = File('${directory.path}/push_registration.json');
      expect(
        await file.readAsString(),
        isNot(contains('DEMO-long-device-token')),
      );
      await file.writeAsString('corrupt');
      await expectLater(service.read(), throwsA(isA<AppFailure>()));
      await service.clear();
      expect(await service.read(), isNull);
    },
  );
  testWidgets(
    'Bandeja privada, preferencia, leído y revocación con texto ampliado en ambos temas',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1100);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final session = auth.FakeAuthRepository(auth.alice),
          membership = groups.FakeGroups();
      final native = Messaging(),
          cloud = Notices(),
          local = LocalRegistration();
      final container = ProviderContainer(
        overrides: [
          firebaseStartupProvider.overrideWithValue(
            FirebaseStartup.ready(auth.FakeApp()),
          ),
          authRepositoryProvider.overrideWithValue(session),
          userProfileRepositoryProvider.overrideWithValue(
            auth.FakeProfileRepository(),
          ),
          groupRepositoryProvider.overrideWithValue(membership),
          groupServerConfirmedProvider.overrideWith(
            (ref, id) => Stream.value(true),
          ),
          photoPresentationProvider.overrideWith(
            (ref, target) => (bytes: null, loading: false),
          ),
          pushDeviceRepositoryProvider.overrideWithValue(
            PushDeviceRepository(native, cloud, local),
          ),
          notificationRepositoryProvider.overrideWithValue(
            NotificationRepository(cloud),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await session.changes.close();
        await membership.changes.close();
        await native.close();
        await cloud.changes.close();
      });
      Future<void> pump(ThemeMode theme) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: BoteParroquialApp(themeMode: theme),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pump(ThemeMode.dark);
      container.read(routerProvider).go('/groups/a/notifications');
      await tester.pumpAndSettle();
      expect(native.permissionRequests, 0);
      expect(find.text('DEMO: aviso ajeno'), findsNothing);
      Future<void> tap(String label) async {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      await tap('Solo bandeja');
      expect(cloud.preference, false);
      await tap('Marcar como leído');
      expect(find.text('Leído'), findsOneWidget);
      await tap('Activar avisos en este móvil');
      expect(native.permissionRequests, 1);
      expect(cloud.devices, hasLength(1));
      final router = container.read(routerProvider);
      router.go('/profile');
      await tester.pumpAndSettle();
      native.taps.add(
        const NotificationOpen(groupId: 'a', recipientUid: 'bob'),
      );
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/profile');
      native.taps.add(
        const NotificationOpen(groupId: 'a', recipientUid: 'alice'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lo que merece tu atención'), findsOneWidget);
      expect(find.text('DEMO: tu recordatorio'), findsOneWidget);
      await pump(ThemeMode.light);
      expect(tester.takeException(), isNull);
      membership.current = [];
      membership.changes.add([]);
      await tester.pumpAndSettle();
      expect(find.text('DEMO: tu recordatorio'), findsNothing);
      final subscription = container.listen(
        notificationsProvider('a'),
        (_, _) {},
      );
      final removed = container.read(notificationsProvider('a').future);
      await tester.pumpAndSettle();
      expect(await removed, isEmpty);
      subscription.close();
      expect(tester.takeException(), isNull);
    },
  );
}
