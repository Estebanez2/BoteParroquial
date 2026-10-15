import '../models/auth_user.dart';
import '../services/auth_service.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  Future<AuthUser> signInWithGoogle();
  Future<void> signOut();
}

class DefaultAuthRepository implements AuthRepository {
  const DefaultAuthRepository(this._service);
  final AuthService _service;
  @override
  Stream<AuthUser?> authStateChanges() => _service.authStateChanges();
  @override
  Future<AuthUser> signInWithGoogle() => _service.signInWithGoogle();
  @override
  Future<void> signOut() => _service.signOut();
}
