class Group {
  const Group({
    required this.id,
    required this.name,
    required this.currency,
    required this.timeZone,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });
  final String id;
  final String name;
  final String? description;
  final String currency;
  final String timeZone;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
}
