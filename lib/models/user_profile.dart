class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.photoUrl,
    this.lastSignInAt,
  });
  final String uid;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSignInAt;
}
