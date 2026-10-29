import '../core/errors/app_failure.dart';
import '../services/account_lifecycle_service.dart';
import 'auth_repository.dart';
import 'group_invitation_repository.dart';

class AccountLifecycleRepository {
  const AccountLifecycleRepository(
    this._service,
    this._auth,
    this._invitations,
  );
  final AccountLifecycleService _service;
  final AuthRepository _auth;
  final GroupInvitationRepository _invitations;
  Future<bool> isClosing(String uid) async =>
      await _service.current(uid) != null;
  Future<bool> close(String uid) async {
    try {
      await _auth.reauthenticateWithGoogle(uid);
      var closure = await _service.current(uid);
      if (closure == null) {
        final memberships = await _service.memberships(uid);
        await _service.checkNoOwnedGroups(uid, memberships);
        for (final member in memberships.where((m) => m.isActive)) {
          await _invitations.remove(member.groupId, uid, member);
        }
        await _service.begin(
          uid,
          memberships.map((m) => m.groupId).toSet().toList(),
        );
        closure = await _service.current(uid);
      }
      if (closure == null) {
        throw const AppFailure(
          FailureCode.network,
          'No se confirmó la preparación de la baja.',
        );
      }
      if (closure.preparing) closure = await _service.seal(uid);
      return await _service.cleanupAndDelete(uid, closure);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure(
        FailureCode.network,
        'No se pudo completar la baja. Comprueba la conexión y reanuda desde la misma cuenta.',
      );
    }
  }
}
