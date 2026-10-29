import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/errors/app_failure.dart';
import '../models/group_notification.dart';
import 'notification_service.dart';

final class FirebasePushMessagingService implements PushMessagingService {
  FirebasePushMessagingService(this._auth);
  final FirebaseAuth _auth;
  FirebaseMessaging get _sdk => FirebaseMessaging.instance;
  @override
  String? get currentUid => _auth.currentUser?.uid;
  @override
  String get platform => Platform.isIOS ? 'ios' : 'android';
  @override
  Future<bool> authorized({bool request = false}) async {
    try {
      final settings = request
          ? await _sdk.requestPermission()
          : await _sdk.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      throw _failure;
    }
  }

  @override
  Future<String?> token() async {
    try {
      if (Platform.isIOS && await _sdk.getAPNSToken() == null) {
        throw const AppFailure(
          FailureCode.configuration,
          'Los avisos de iPhone necesitan completar APNs y probarse en un dispositivo Apple.',
        );
      }
      await _sdk.setAutoInitEnabled(true);
      return await _sdk.getToken();
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw _failure;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _sdk.setAutoInitEnabled(false);
      await _sdk.deleteToken();
    } catch (_) {
      throw _failure;
    }
  }

  @override
  Stream<void> get tokenChanges => _sdk.onTokenRefresh.map((_) {});
  NotificationOpen? _open(RemoteMessage? message) {
    final group = message?.data['groupId'], uid = message?.data['recipientUid'];
    if (group is! String ||
        uid is! String ||
        group.isEmpty ||
        uid.isEmpty ||
        group.contains('/') ||
        group == '.' ||
        group == '..' ||
        group.length > 256 ||
        uid.length > 128) {
      return null;
    }
    return NotificationOpen(groupId: group, recipientUid: uid);
  }

  @override
  Stream<NotificationOpen> get opened => FirebaseMessaging.onMessageOpenedApp
      .map(_open)
      .where((event) => event != null)
      .cast<NotificationOpen>();
  @override
  Future<NotificationOpen?> initialOpen() async =>
      _open(await _sdk.getInitialMessage());
  static const _failure = AppFailure(
    FailureCode.network,
    'No pudimos configurar los avisos del móvil. Comprueba la conexión y los permisos del sistema.',
  );
}
