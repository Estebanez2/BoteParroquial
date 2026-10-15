abstract final class FirestorePaths {
  static String _id(String value) {
    if (value.trim().isEmpty ||
        value.contains('/') ||
        value == '.' ||
        value == '..') {
      throw ArgumentError.value(value, 'id', 'ID de documento no válido');
    }
    return value;
  }

  static String user(String uid) => 'users/${_id(uid)}';
  static String group(String groupId) => 'groups/${_id(groupId)}';
  static String members(String groupId) => '${group(groupId)}/members';
  static String member(String groupId, String uid) =>
      '${members(groupId)}/${_id(uid)}';
  static String persons(String groupId) => '${group(groupId)}/persons';
  static String person(String groupId, String personId) =>
      '${persons(groupId)}/${_id(personId)}';
  static String movements(String groupId) => '${group(groupId)}/movements';
  static String movement(String groupId, String movementId) =>
      '${movements(groupId)}/${_id(movementId)}';
}
