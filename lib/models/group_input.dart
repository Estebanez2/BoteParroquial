class GroupInput {
  const GroupInput({
    required this.name,
    required this.description,
    required this.currency,
    required this.timeZone,
    required this.createOwnerPerson,
  });
  final String name, description, currency, timeZone;
  final bool createOwnerPerson;
}
