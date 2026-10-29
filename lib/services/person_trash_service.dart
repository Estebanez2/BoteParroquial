import '../models/person.dart';
import '../models/trashed_person.dart';

abstract interface class PersonTrashService {
  Stream<List<TrashedPerson>> watch(String groupId);
  Future<void> trash(String groupId, String actorUid, Person person);
  Future<void> restore(String groupId, String actorUid, TrashedPerson person);
  Future<void> purge(String groupId, String actorUid, TrashedPerson person);
}
