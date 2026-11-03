import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../core/errors/app_failure.dart';
import '../models/group_notification.dart';
import '../services/notification_service.dart';

final class PushDeviceRepository {
  PushDeviceRepository(
    this._messaging,
    this._devices,
    this._local, {
    this.consent,
  });
  final PushConsentService? consent;
  final PushMessagingService _messaging;
  final NotificationService _devices;
  final PushRegistrationService _local;
  Future<void> _queue = Future.value();
  Future<T> _locked<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  void _check(String uid) {
    if (uid.isEmpty || _messaging.currentUid != uid) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'La sesión ha cambiado. Vuelve a abrir tus avisos.',
      );
    }
  }

  Stream<void> get tokenChanges => _messaging.tokenChanges;
  Stream<NotificationOpen> get opened => _messaging.opened;
  Future<NotificationOpen?> initialOpen() => _messaging.initialOpen();

  Future<bool> enable(String uid) => _locked(() async {
    _check(uid);
    final old = await _local.read();
    if (old != null && (old.uid != uid || !old.enabled)) await _remove(old);
    if (!await _messaging.authorized(request: true)) {
      await consent?.write(uid, false);
      throw const AppFailure(
        FailureCode.permissionDenied,
        'No se concedió permiso. Puedes activarlo en los ajustes de notificaciones del móvil.',
      );
    }
    _check(uid);
    await consent?.write(uid, true);
    return _register(uid);
  });
  Future<bool> resume(String uid) => _locked(() async {
    _check(uid);
    final registration = await _local.read();
    if (registration == null) {
      final consent = this.consent;
      if (consent == null) return false;
      final choice = await consent.read(uid);
      _check(uid);
      if (choice == false) return false;
      // Persist before showing the OS dialog: denial/interruption never loops.
      if (choice == null) await consent.write(uid, false);
      final granted = await _messaging.authorized(request: choice == null);
      _check(uid);
      await consent.write(uid, granted);
      return granted ? _register(uid) : false;
    }
    if (!registration.enabled) {
      await consent?.write(uid, false);
      await _remove(registration);
      return false;
    }
    if (registration.uid != uid) {
      await _remove(registration);
      return false;
    }
    if (!await _messaging.authorized()) {
      await _remove(registration);
      return false;
    }
    return _register(uid);
  });
  Future<bool> _register(String uid) async {
    _check(uid);
    final token = await _messaging.token();
    _check(uid);
    if (token == null || token.length < 16 || token.length > 4096) {
      throw const AppFailure(
        FailureCode.network,
        'El móvil todavía no ha recibido su registro. Reintenta en unos segundos.',
      );
    }
    final previous = await _local.read();
    final id = sha256.convert(utf8.encode(token)).toString();
    final ids = <String>{
      if (previous?.uid == uid) ...previous!.tokenIds,
      id,
    }.toList();
    // Persist intent before sending: an uncertain registration can be withdrawn.
    await _local.write(PushRegistration(uid: uid, tokenIds: ids));
    _check(uid);
    await _devices.registerDevice(uid, token, _messaging.platform, ids);
    _check(uid);
    await _local.write(PushRegistration(uid: uid, tokenIds: [id]));
    return true;
  }

  Future<void> disable() => _locked(() async {
    final uid = _messaging.currentUid;
    if (uid != null) await consent?.write(uid, false);
    final registration = await _local.read();
    if (registration != null) await _remove(registration);
  });
  Future<void> beforeSignOut() => disable();
  Future<void> _remove(PushRegistration registration) async {
    // A crash/offline failure must resume withdrawal, never re-enable implicitly.
    await _local.write(
      PushRegistration(
        uid: registration.uid,
        tokenIds: registration.tokenIds,
        enabled: false,
      ),
    );
    // Normal logout waits for server confirmation while the old session exists.
    if (_messaging.currentUid == registration.uid) {
      await _devices.unregisterDevices(registration.uid, registration.tokenIds);
    }
    // On an unexpected external account change invalidate the old native token;
    // never try to modify the old user's registry under the new identity.
    await _messaging.stop();
    await _local.clear();
  }
}
