import '../models/auth_user.dart';
import '../services/auth_service.dart';
import 'push_device_repository.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  Future<AuthUser> signInWithGoogle();
  Future<void> reauthenticateWithGoogle(String expectedUid);
  Future<void> signOut();
}

class DefaultAuthRepository implements AuthRepository {
  const DefaultAuthRepository(this._service, [this._pushDevices]);
  final AuthService _service;
  final PushDeviceRepository? _pushDevices;
  @override
  Stream<AuthUser?> authStateChanges() => _service.authStateChanges();
  @override
  Future<AuthUser> signInWithGoogle() => _service.signInWithGoogle();
  @override
  Future<void> reauthenticateWithGoogle(String expectedUid) =>
      _service.reauthenticateWithGoogle(expectedUid);
  @override
  Future<void> signOut() async {
    await _pushDevices?.beforeSignOut();
    await _service.signOut();
  }
}
