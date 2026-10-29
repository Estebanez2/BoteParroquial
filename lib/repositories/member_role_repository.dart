import '../core/errors/app_failure.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/person.dart';
import '../services/member_role_service.dart';

class MemberRoleRepository {
  const MemberRoleRepository(this._service);
  final MemberRoleService _service;

  static bool hasActivePerson(GroupMember member, Person? person) =>
      member.isActive &&
      person != null &&
      person.isActive &&
      person.groupId == member.groupId &&
      person.id == member.personId &&
      person.linkedUid == member.uid;

  static GroupRole? nextRole(GroupMember target, Person? person) {
    if (!target.isActive || target.role == GroupRole.owner) return null;
    if (target.role == GroupRole.admin) return GroupRole.member;
    return hasActivePerson(target, person) ? GroupRole.admin : null;
  }

  static bool canReceiveOwnership(
    GroupMember owner,
    GroupMember target,
    Person? person,
  ) =>
      owner.isActive &&
      owner.role == GroupRole.owner &&
      target.groupId == owner.groupId &&
      target.uid != owner.uid &&
      target.role != GroupRole.owner &&
      hasActivePerson(target, person);

  static String? confirmationError(String expected, String? value) =>
      value == expected ? null : 'Escribe exactamente el nombre del grupo.';

  Future<void> changeRole(
    String groupId,
    String actorUid,
    GroupMember target,
    Person? person,
    GroupRole role,
  ) {
    if (target.groupId != groupId ||
        nextRole(target, person) != role ||
        (target.uid == actorUid && role == GroupRole.admin)) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'Este cambio de rol no está permitido. Para ascender necesita una persona activa vinculada.',
      );
    }
    return _service.changeRole(groupId, actorUid, target, role);
  }

  Future<void> transfer(
    Group group,
    GroupMember owner,
    GroupMember recipient,
    Person? person,
    String confirmation,
  ) {
    if (group.id != owner.groupId ||
        !group.isActive ||
        !canReceiveOwnership(owner, recipient, person) ||
        confirmationError(group.name, confirmation) != null) {
      throw const AppFailure(
        FailureCode.invalidData,
        'Revisa el nombre del grupo y elige un miembro con persona activa vinculada.',
      );
    }
    return _service.transfer(group, owner, recipient);
  }
}
