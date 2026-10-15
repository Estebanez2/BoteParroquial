import '../models/auth_user.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';

abstract interface class UserProfileRepository {
  Future<UserProfile> ensureProfile(AuthUser user);
}

class DefaultUserProfileRepository implements UserProfileRepository {
  const DefaultUserProfileRepository(this._service);
  final UserProfileService _service;
  @override
  Future<UserProfile> ensureProfile(AuthUser user) =>
      _service.ensureProfile(user);
}
