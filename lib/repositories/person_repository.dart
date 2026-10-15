import '../core/errors/app_failure.dart';
import '../models/person.dart';
import '../services/person_service.dart';

class PersonRepository {
  const PersonRepository(this._service);
  final PersonService _service;
  Stream<List<Person>> watchPersons(String groupId) =>
      _service.watchPersons(groupId);
  static String? nameError(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Escribe el nombre de la persona.';
    if (name.length > 256) return 'El nombre admite hasta 256 caracteres.';
    return null;
  }

  static String? notesError(String? value) => (value?.trim().length ?? 0) > 2000
      ? 'Las notas admiten hasta 2000 caracteres.'
      : null;
  static String? _notes(String? value) {
    final result = value?.trim();
    return result == null || result.isEmpty ? null : result;
  }

  void _validate(String name, String? notes) {
    final error = nameError(name) ?? notesError(notes);
    if (error != null) throw AppFailure(FailureCode.invalidData, error);
  }

  void _scope(String groupId, Person person) {
    if (person.groupId != groupId) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'La persona pertenece a otro grupo.',
      );
    }
  }

  Future<void> create(
    String groupId,
    String actorUid,
    String name,
    String? notes,
  ) {
    _validate(name, notes);
    return _service.create(groupId, actorUid, name.trim(), _notes(notes));
  }

  Future<void> edit(
    String groupId,
    String actorUid,
    Person person,
    String name,
    String? notes,
  ) {
    _scope(groupId, person);
    _validate(name, notes);
    return _service.edit(groupId, actorUid, person, name.trim(), _notes(notes));
  }

  Future<void> setActive(
    String groupId,
    String actorUid,
    Person person,
    bool active,
  ) {
    _scope(groupId, person);
    return _service.setActive(groupId, actorUid, person, active);
  }
}
