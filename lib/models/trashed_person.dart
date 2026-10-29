import 'person.dart';

class TrashedPerson {
  const TrashedPerson({
    required this.person,
    required this.trashedAt,
    required this.expiresAt,
  });
  final Person person;
  final DateTime trashedAt, expiresAt;
}
