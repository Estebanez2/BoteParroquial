import '../models/person.dart';
import '../models/year_month.dart';

abstract interface class PersonService {
  String newId(String groupId);
  Stream<List<Person>> watchPersons(String groupId);
  Future<void> create(
    String groupId,
    String actorUid,
    String name,
    String? notes, {
    String? id,
    YearMonth? firstMonth,
  });
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
