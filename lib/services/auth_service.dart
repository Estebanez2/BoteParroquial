import '../models/auth_user.dart';

abstract interface class AuthService {
  Stream<AuthUser?> authStateChanges();
  Future<AuthUser> signInWithGoogle();
  Future<void> signOut();
}
