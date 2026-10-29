class AccountClosure {
  AccountClosure({
    required this.preparing,
    required List<String> groupIds,
    this.closingAt,
  }) : groupIds = List.unmodifiable(groupIds);
  final bool preparing;
  final List<String> groupIds;
  final DateTime? closingAt;
}
