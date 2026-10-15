import '../models/person.dart';

abstract interface class PersonService {
  Stream<List<Person>> watchPersons(String groupId);
  Future<void> create(
    String groupId,
    String actorUid,
    String name,
    String? notes,
  );
  Future<void> edit(
    String groupId,
    String actorUid,
    Person person,
    String name,
    String? notes,
  );
  Future<void> setActive(
    String groupId,
    String actorUid,
    Person person,
    bool isActive,
  );
}
