class GroupDeletionPreview {
  const GroupDeletionPreview({
    required this.groupId,
    required this.name,
    required this.balanceCents,
    required this.currency,
    required this.persons,
    required this.members,
    required this.movements,
  });
  final String groupId, name, currency;
  final int balanceCents, persons, members, movements;
}

class GroupDeletionTask {
  const GroupDeletionTask({required this.groupId, required this.groupName});
  final String groupId, groupName;
}
