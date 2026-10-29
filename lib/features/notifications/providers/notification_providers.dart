import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../models/group_notification.dart';
import '../../../repositories/notification_repository.dart';
import '../../../services/firestore_notification_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../groups/providers/group_providers.dart';
import 'push_device_providers.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(
    FirestoreNotificationService(ref.watch(firestoreProvider)),
  ),
);

String? _uid(Ref ref, String groupId) {
  final session = ref.watch(authStateProvider);
  final member = ref.watch(currentMembershipProvider(groupId));
  final group = ref.watch(groupProvider(groupId));
  if (session.isLoading ||
      session.hasError ||
      member == null ||
      group.isLoading ||
      group.hasError ||
      group.asData?.value == null) {
    return null;
  }
  final uid = session.asData?.value?.uid;
  return member.uid == uid ? uid : null;
}

final notificationsProvider = StreamProvider.autoDispose
    .family<List<GroupNotification>, String>((ref, groupId) {
      final uid = _uid(ref, groupId);
      if (uid == null) return Stream.value(const []);
      return ref.watch(notificationRepositoryProvider).watchInbox(groupId, uid);
    }, retry: (_, _) => null);
final quotaPushEnabledProvider = StreamProvider.autoDispose
    .family<bool, String>((ref, groupId) {
      final uid = _uid(ref, groupId);
      if (uid == null) return Stream.value(false);
      return ref
          .watch(notificationRepositoryProvider)
          .watchQuotaPushEnabled(groupId, uid);
    }, retry: (_, _) => null);

final notificationActionProvider = NotifierProvider.autoDispose
    .family<NotificationAction, AsyncValue<void>, String>(
      NotificationAction.new,
    );

final activityPushEnabledProvider = StreamProvider.autoDispose
    .family<bool, (String, ActivityNotificationCategory)>((ref, key) {
      final uid = _uid(ref, key.$1);
      if (uid == null) return Stream.value(false);
      return ref
          .watch(notificationRepositoryProvider)
          .watchActivityPushEnabled(key.$1, uid, key.$2);
    }, retry: (_, _) => null);

class NotificationAction extends Notifier<AsyncValue<void>> {
  NotificationAction(this.groupId);
  final String groupId;
  @override
  AsyncValue<void> build() {
    ref.watch(authStateProvider);
    return const AsyncData(null);
  }

  Future<void> preference(bool enabled) =>
      _perform((repo, uid) => repo.setQuotaPushEnabled(groupId, uid, enabled));
  Future<void> activityPreference(
    ActivityNotificationCategory category,
    bool enabled,
  ) => _perform(
    (repo, uid) => repo.setActivityPushEnabled(groupId, uid, category, enabled),
  );
  Future<void> markRead(String id) =>
      _perform((repo, uid) => repo.markRead(groupId, uid, id));
  Future<void> _perform(
    Future<void> Function(NotificationRepository, String) action,
  ) async {
    if (state.isLoading) return;
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null ||
        ref.read(currentMembershipProvider(groupId))?.uid != user.uid ||
        ref.read(groupProvider(groupId)).asData?.value == null) {
      return;
    }
    final repo = ref.read(notificationRepositoryProvider);
    state = const AsyncLoading();
    try {
      await action(repo, user.uid);
      if (ref.mounted &&
          ref.read(authStateProvider).asData?.value?.uid == user.uid) {
        state = const AsyncData(null);
      }
    } catch (e, s) {
      if (ref.mounted &&
          ref.read(authStateProvider).asData?.value?.uid == user.uid) {
        state = AsyncError(e, s);
      }
    }
  }
}

final notificationOpenProvider =
    NotifierProvider<NotificationOpenController, NotificationOpen?>(
      NotificationOpenController.new,
    );

class NotificationOpenController extends Notifier<NotificationOpen?> {
  @override
  NotificationOpen? build() {
    ref.watch(authStateProvider);
    return null;
  }

  void receive(NotificationOpen event) {
    if (ref.read(authStateProvider).asData?.value?.uid == event.recipientUid) {
      state = event;
    }
  }

  void clear() => state = null;
}

final pushDeviceControllerProvider =
    AsyncNotifierProvider<PushDeviceController, bool>(PushDeviceController.new);

class PushDeviceController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final session = ref.watch(authStateProvider);
    final user = session.isLoading || session.hasError
        ? null
        : session.asData?.value;
    if (user == null) return false;
    final repo = ref.watch(pushDeviceRepositoryProvider);
    final openController = ref.read(notificationOpenProvider.notifier);
    final active = await repo.resume(user.uid);
    if (!ref.mounted || !active) return false;
    final refresh = repo.tokenChanges.listen(
      (_) => unawaited(_resume(user.uid)),
      onError: (Object _, StackTrace _) {},
    );
    final opened = repo.opened.listen(
      openController.receive,
      onError: (Object _, StackTrace _) {},
    );
    ref.onDispose(() {
      unawaited(refresh.cancel());
      unawaited(opened.cancel());
    });
    final initial = await repo.initialOpen();
    if (ref.mounted && initial != null) openController.receive(initial);
    return true;
  }

  Future<void> _resume(String uid) async {
    final repo = ref.read(pushDeviceRepositoryProvider);
    try {
      final result = await repo.resume(uid);
      if (ref.mounted &&
          ref.read(authStateProvider).asData?.value?.uid == uid) {
        state = AsyncData(result);
      }
    } catch (e, s) {
      if (ref.mounted &&
          ref.read(authStateProvider).asData?.value?.uid == uid) {
        state = AsyncError(e, s);
      }
    }
  }

  Future<void> refresh() async {
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid != null && !state.isLoading) await _resume(uid);
  }

  Future<void> enable() async {
    if (state.isLoading) return;
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;
    final repo = ref.read(pushDeviceRepositoryProvider);
    state = const AsyncLoading();
    try {
      await repo.enable(user.uid);
      if (ref.mounted &&
          ref.read(authStateProvider).asData?.value?.uid == user.uid) {
        ref.invalidateSelf(); // Attach refresh/open listeners once consent exists.
      }
    } catch (e, s) {
      if (ref.mounted &&
          ref.read(authStateProvider).asData?.value?.uid == user.uid) {
        state = AsyncError(e, s);
      }
    }
  }

  Future<void> disable() async {
    if (state.isLoading) return;
    final repo = ref.read(pushDeviceRepositoryProvider);
    state = const AsyncLoading();
    try {
      await repo.disable();
      if (ref.mounted) ref.invalidateSelf();
    } catch (e, s) {
      if (ref.mounted) state = AsyncError(e, s);
    }
  }
}
