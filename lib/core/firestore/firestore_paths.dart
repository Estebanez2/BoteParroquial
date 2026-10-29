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
  static String auditEvents(String groupId) => '${group(groupId)}/auditEvents';
  static String auditEvent(String groupId, String eventId) =>
      '${auditEvents(groupId)}/${_id(eventId)}';
  static String invitationSettings(String groupId) =>
      '${group(groupId)}/invitationSettings/current';
  static String invitation(String groupId, String code) =>
      '${group(groupId)}/invitations/${_id(code)}';
  static String joinRequests(String groupId) =>
      '${group(groupId)}/joinRequests';
  static String joinRequest(String groupId, String uid) =>
      '${joinRequests(groupId)}/${_id(uid)}';
  static String quotaRules(String groupId) => '${group(groupId)}/quotaRules';
  static String quotaRule(String groupId, String id) =>
      '${quotaRules(groupId)}/${_id(id)}';
  static String quotaSettings(String groupId) =>
      '${group(groupId)}/quotaSettings/current';
  static String allocations(String groupId) => '${group(groupId)}/allocations';
  static String allocation(String groupId, String id) =>
      '${allocations(groupId)}/${_id(id)}';
  static String allocationBalance(String groupId, String movementId) =>
      '${group(groupId)}/allocationBalances/${_id(movementId)}';
  static String refundOperation(String groupId, String id) =>
      auditEvent(groupId, id);
  static String participationPeriods(String groupId) =>
      '${group(groupId)}/participationPeriods';
  static String participationPeriod(String groupId, String id) =>
      '${participationPeriods(groupId)}/${_id(id)}';
}
