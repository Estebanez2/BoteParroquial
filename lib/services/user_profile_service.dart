import '../models/auth_user.dart';
import '../models/user_profile.dart';

abstract interface class UserProfileService {
  Future<UserProfile> ensureProfile(AuthUser user);
}
