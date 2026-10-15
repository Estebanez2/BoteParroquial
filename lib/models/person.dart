class Person {
  const Person({
    required this.id,
    required this.groupId,
    required this.displayName,
    required this.isActive,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });
  final String id;
  final String groupId;
  final String displayName;
  final String? notes;
  final bool isActive;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
}
