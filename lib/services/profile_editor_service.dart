import '../models/user_profile.dart';

abstract interface class ProfileEditorService {
  Future<void> rename(UserProfile original, String name);
}
