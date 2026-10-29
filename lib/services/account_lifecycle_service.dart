import '../models/account_closure.dart';
import '../models/group_member.dart';

abstract interface class AccountLifecycleService {
  Future<AccountClosure?> current(String uid);
  Future<List<GroupMember>> memberships(String uid);
  Future<void> checkNoOwnedGroups(String uid, List<GroupMember> memberships);
  Future<void> begin(String uid, List<String> groups);
  Future<AccountClosure> seal(String uid);
  Future<bool> cleanupAndDelete(String uid, AccountClosure closure);
}
