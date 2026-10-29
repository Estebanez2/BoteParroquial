import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/models/account_closure.dart';
import 'package:bote_parroquial/models/group_member.dart';
import 'package:bote_parroquial/repositories/account_lifecycle_repository.dart';
import 'package:bote_parroquial/repositories/auth_repository.dart';
import 'package:bote_parroquial/repositories/group_invitation_repository.dart';
import 'package:bote_parroquial/services/account_lifecycle_service.dart';
import 'package:bote_parroquial/services/file_sharing_service.dart';
import 'package:bote_parroquial/services/group_invitation_service.dart';
import 'package:flutter_test/flutter_test.dart';

GroupMember member({GroupRole role = GroupRole.member}) => GroupMember(
  groupId: 'a',
  uid: 'alice',
  displayName: 'Ana',
  role: role,
  isActive: true,
  joinedAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

class _Auth extends Fake implements AuthRepository {
  bool cancelled = false;
  @override
  Future<void> reauthenticateWithGoogle(String expectedUid) async {
    expect(expectedUid, 'alice');
    if (cancelled) throw const AppFailure(FailureCode.cancelled, 'Cancelado');
  }
}

class _Account extends Fake implements AccountLifecycleService {
  bool owner = false, allowFinish = false, left = false;
  int deletionAttempts = 0;
  AccountClosure? saved;
  @override
  Future<AccountClosure?> current(String uid) async => saved;
  @override
  Future<List<GroupMember>> memberships(String uid) async => [
    member(role: owner ? GroupRole.owner : GroupRole.member),
  ];
  @override
  Future<void> checkNoOwnedGroups(
    String uid,
    List<GroupMember> memberships,
  ) async {
    if (owner) {
      throw const AppFailure(FailureCode.invalidData, 'Transfiere antes');
    }
  }

  @override
  Future<void> begin(String uid, List<String> groups) async {
    expect(left, true);
    saved = AccountClosure(preparing: true, groupIds: groups);
  }

  @override
  Future<AccountClosure> seal(String uid) async => saved = AccountClosure(
    preparing: false,
    groupIds: saved!.groupIds,
    closingAt: DateTime.utc(2026),
  );
  @override
  Future<bool> cleanupAndDelete(String uid, AccountClosure closure) async {
    expect(left, true);
    expect(closure.preparing, false);
    deletionAttempts++;
    return allowFinish;
  }
}

class _Invitations extends Fake implements GroupInvitationService {
  _Invitations(this.account);
  final _Account account;
  int exits = 0;
  @override
  Future<void> remove(String groupId, String uid, GroupMember target) async {
    expect(target.role, isNot(GroupRole.owner));
    account.left = true;
    exits++;
  }
}

class _Sharing extends Fake implements FileSharingService {}

void main() {
  test(
    'No retira accesos ni borra identidad si Google se cancela o conserva propiedad',
    () async {
      final account = _Account(),
          auth = _Auth(),
          invitations = _Invitations(account);
      final repo = AccountLifecycleRepository(
        account,
        auth,
        GroupInvitationRepository(invitations, _Sharing()),
      );
      auth.cancelled = true;
      await expectLater(repo.close('alice'), throwsA(isA<AppFailure>()));
      auth.cancelled = false;
      account.owner = true;
      await expectLater(repo.close('alice'), throwsA(isA<AppFailure>()));
      expect(account.saved, isNull);
      expect(account.deletionAttempts, 0);
      expect(invitations.exits, 0);
    },
  );
  test(
    'Retira membresía antes de borrar cuenta y reanuda sin repetir la salida',
    () async {
      final account = _Account(), invitations = _Invitations(account);
      final repo = AccountLifecycleRepository(
        account,
        _Auth(),
        GroupInvitationRepository(invitations, _Sharing()),
      );
      expect(await repo.close('alice'), false);
      expect(account.saved?.preparing, false);
      account.allowFinish = true;
      expect(await repo.close('alice'), true);
      expect(invitations.exits, 1);
    },
  );
}
