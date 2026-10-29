import '../models/person.dart';
import '../models/trashed_person.dart';
import '../services/person_trash_service.dart';

class PersonTrashRepository {
  const PersonTrashRepository(this._service);
  final PersonTrashService _service;
  Stream<List<TrashedPerson>> watch(String groupId) => _service.watch(groupId);
  Future<void> trash(String groupId, String uid, Person person) =>
      _service.trash(groupId, uid, person);
  Future<void> restore(String groupId, String uid, TrashedPerson person) =>
      _service.restore(groupId, uid, person);
  Future<void> purge(String groupId, String uid, TrashedPerson person) =>
      _service.purge(groupId, uid, person);
  bool canRestore(TrashedPerson person, DateTime now) =>
      now.isBefore(person.expiresAt);
}
