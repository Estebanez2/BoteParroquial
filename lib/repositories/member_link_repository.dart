import '../core/errors/app_failure.dart';
import '../models/group_member.dart';
import '../models/person.dart';
import '../services/member_link_service.dart';

class MemberLinkRepository {
  const MemberLinkRepository(this._service);
  final MemberLinkService _service;
  static bool losesAdmin(GroupMember target, Person? next) =>
      target.role == GroupRole.admin && next?.isActive != true;
  Future<void> change(
    String groupId,
    String actorUid,
    GroupMember target,
    Person? previous,
    Person? next,
  ) {
    if (target.groupId != groupId ||
        (previous != null && previous.groupId != groupId) ||
        (next != null && next.groupId != groupId) ||
        previous?.id != target.personId ||
        (previous != null && previous.linkedUid != target.uid) ||
        (next?.linkedUid != null && next!.linkedUid != target.uid)) {
      throw const AppFailure(
        FailureCode.invalidData,
        'El vínculo ha cambiado o esa persona pertenece a otra cuenta. Actualiza antes de continuar.',
      );
    }
    if (target.role == GroupRole.owner && target.uid != actorUid) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'Solo el propietario puede cambiar su propia vinculación.',
      );
    }
    if (!target.isActive && next != null) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'Primero debe aprobarse la vuelta al grupo. Puedes quitar el vínculo anterior expresamente.',
      );
    }
    if (previous?.id == next?.id) return Future.value();
    return _service.change(groupId, actorUid, target, previous, next);
  }
}
