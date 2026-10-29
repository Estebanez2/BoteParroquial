import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/errors/app_failure.dart';
import '../models/auth_user.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth, this._google);
  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _initialization;

  AuthUser _map(User user) => AuthUser(
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoUrl: user.photoURL,
  );

  Future<void> _initializeGoogle() async {
    try {
      await (_initialization ??= _google.initialize());
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  @override
  Stream<AuthUser?> authStateChanges() async* {
    try {
      await for (final user in _auth.authStateChanges()) {
        yield user == null ? null : _map(user);
      }
    } on FirebaseAuthException catch (error) {
      throw _firebaseFailure(error);
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      await _initializeGoogle();
      final account = await _google.authenticate();
      final token = account.authentication.idToken;
      if (token == null) {
        throw const AppFailure(
          FailureCode.configuration,
          'Google no ha devuelto una credencial válida.',
        );
      }
      final result = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: token),
      );
      final user = result.user;
      if (user == null) {
        throw const AppFailure(
          FailureCode.unknown,
          'No se pudo identificar la cuenta.',
        );
      }
      return _map(user);
    } on GoogleSignInException catch (error) {
      throw switch (error.code) {
        GoogleSignInExceptionCode.canceled => const AppFailure(
          FailureCode.cancelled,
          'Acceso cancelado.',
        ),
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode
            .providerConfigurationError => const AppFailure(
          FailureCode.configuration,
          'Google Sign-In no está disponible. Revisa la configuración de la aplicación.',
        ),
        _ => const AppFailure(
          FailureCode.unknown,
          'No se pudo acceder con Google. Comprueba tu conexión e inténtalo de nuevo.',
        ),
      };
    } on FirebaseAuthException catch (error) {
      throw _firebaseFailure(error);
    }
  }

  @override
  Future<void> reauthenticateWithGoogle(String expectedUid) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.uid != expectedUid) throw _sessionChanged;
      await _initializeGoogle();
      final account = await _google.authenticate();
      final token = account.authentication.idToken;
      if (_auth.currentUser?.uid != expectedUid) throw _sessionChanged;
      if (token == null) {
        throw const AppFailure(
          FailureCode.configuration,
          'Google no ha devuelto una credencial válida.',
        );
      }
      // Reauthenticate the existing Firebase user; never replace their session.
      final result = await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(idToken: token),
      );
      if (result.user?.uid != expectedUid ||
          _auth.currentUser?.uid != expectedUid) {
        throw _sessionChanged;
      }
      await user.getIdToken(true);
      if (_auth.currentUser?.uid != expectedUid) throw _sessionChanged;
    } on GoogleSignInException catch (error) {
      throw AppFailure(
        error.code == GoogleSignInExceptionCode.canceled
            ? FailureCode.cancelled
            : FailureCode.unknown,
        error.code == GoogleSignInExceptionCode.canceled
            ? 'Verificación cancelada. No se ha iniciado la operación.'
            : 'No se pudo verificar Google. Comprueba tu conexión y vuelve a intentarlo.',
      );
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-mismatch') {
        throw const AppFailure(
          FailureCode.permissionDenied,
          'Elige la misma cuenta de Google con la que estás usando la app.',
        );
      }
      throw _firebaseFailure(error);
    }
  }

  static const _sessionChanged = AppFailure(
    FailureCode.permissionDenied,
    'Tu sesión ha cambiado. Abre de nuevo la operación.',
  );

  @override
  Future<void> signOut() async {
    try {
      // Revoke the local Firebase session even if Google cleanup fails.
      await _auth.signOut();
      await _initializeGoogle();
      await _google.signOut();
    } on FirebaseAuthException catch (error) {
      throw _firebaseFailure(error);
    } on GoogleSignInException {
      throw const AppFailure(
        FailureCode.unknown,
        'La sesión se ha cerrado, pero Google no pudo completar la desconexión.',
      );
    }
  }

  AppFailure _firebaseFailure(FirebaseAuthException error) =>
      switch (error.code) {
        'network-request-failed' => const AppFailure(
          FailureCode.network,
          'No hay conexión. Comprueba la red e inténtalo de nuevo.',
        ),
        'user-disabled' => const AppFailure(
          FailureCode.permissionDenied,
          'Esta cuenta está deshabilitada.',
        ),
        'operation-not-allowed' || 'invalid-credential' => const AppFailure(
          FailureCode.configuration,
          'No se pudo autorizar la cuenta de Google. Revisa la configuración.',
        ),
        _ => const AppFailure(
          FailureCode.unknown,
          'No se pudo completar el acceso. Inténtalo de nuevo.',
        ),
      };
}
