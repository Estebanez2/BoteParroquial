import 'dart:typed_data';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../models/photo_target.dart';
import '../../../repositories/photo_repository.dart';
import '../../../services/device_photo_picker_service.dart';
import '../../../services/supabase_photo_service.dart';
import '../../../services/photo_cache_service.dart';
import '../../../models/group_member.dart';
import '../../auth/providers/auth_providers.dart';
import '../../groups/providers/group_providers.dart';

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  final repository = PhotoRepository(
    SupabasePhotoService(ref.watch(supabaseConnectionProvider)),
    DevicePhotoPickerService(ImagePicker()),
    cache: PhotoCacheService.persistent(),
  );
  var uid = ref.read(authStateProvider).asData?.value?.uid;
  ref.listen(authStateProvider, (_, next) {
    if (next.isLoading) return;
    final current = next.asData?.value?.uid;
    if (uid != null && uid != current) {
      unawaited(repository.cache.clearAccount(uid!));
    }
    uid = current;
  });
  ref.listen(membershipsProvider, (previous, next) {
    if (next.isLoading || next.hasError) return;
    final active = next.asData?.value ?? const <GroupMember>[];
    for (final old in previous?.asData?.value ?? const <GroupMember>[]) {
      if (old.isActive &&
          !active.any(
            (m) => m.uid == old.uid && m.groupId == old.groupId && m.isActive,
          )) {
        unawaited(repository.cache.clearGroup(old.uid, old.groupId));
      }
    }
  });
  return repository;
});

// Drop cached images and drafts on session, group or membership changes.
String? _watchActor(Ref ref, PhotoTarget target) {
  final session = ref.watch(authStateProvider);
  if (session.isLoading || session.hasError) return null;
  final user = session.asData?.value;
  if (user == null) return null;
  if (target.kind == PhotoKind.account) {
    return target.id == user.uid ? user.uid : null;
  }
  final groupId = target.groupId!;
  final group = ref.watch(groupProvider(groupId));
  final membership = ref.watch(currentMembershipProvider(groupId));
  if (group.isLoading ||
      group.hasError ||
      group.asData?.value == null ||
      membership == null) {
    return null;
  }
  return user.uid;
}

final photoActorProvider = Provider.autoDispose.family<String?, PhotoTarget>(
  _watchActor,
);

final photoProvider = StreamProvider.autoDispose
    .family<Uint8List?, PhotoTarget>((ref, target) {
      final actor = _watchActor(ref, target);
      if (actor == null) return Stream.value(null);
      return ref.watch(photoRepositoryProvider).watch(actor, target);
    }, retry: (_, _) => null);

/// Synchronous memory path avoids an initial loading frame when a view remounts.
final photoPresentationProvider = Provider.autoDispose
    .family<({Uint8List? bytes, bool loading}), PhotoTarget>((ref, target) {
      final actor = _watchActor(ref, target);
      final state = ref.watch(photoProvider(target));
      if (actor == null) {
        return (bytes: null, loading: ref.watch(authStateProvider).isLoading);
      }
      final error = state.error;
      if (error is AppFailure && error.code == FailureCode.permissionDenied) {
        return (bytes: null, loading: false);
      }
      CachedPhoto? cached;
      try {
        cached = ref.watch(photoRepositoryProvider).cache.peek(actor, target);
      } catch (_) {
        // Missing photo infrastructure must not block other features or previews.
        return (bytes: null, loading: false);
      }
      return (
        bytes: cached != null ? cached.bytes : state.value,
        loading: cached == null && state.isLoading && state.value == null,
      );
    });

final photoRefreshProvider = Provider<void Function(PhotoTarget)>(
  (ref) => (target) {
    final actor = ref.read(photoActorProvider(target));
    if (actor != null) {
      ref.read(photoRepositoryProvider).cache.stale(actor, target);
    }
    ref.invalidate(photoProvider(target));
    ref.invalidate(photoAccessProvider(target));
  },
);

final photoAccessProvider = FutureProvider.autoDispose
    .family<PhotoAccess, PhotoTarget>((ref, target) {
      final actor = _watchActor(ref, target);
      if (actor == null) return const PhotoAccess.denied();
      return ref.watch(photoRepositoryProvider).access(actor, target);
    }, retry: (_, _) => null);

class PhotoEditorState {
  const PhotoEditorState({this.draft, this.busy = false, this.error});
  final Uint8List? draft;
  final bool busy;
  final String? error;
}

final photoControllerProvider = NotifierProvider.autoDispose
    .family<PhotoController, PhotoEditorState, PhotoTarget>(
      PhotoController.new,
    );

class PhotoController extends Notifier<PhotoEditorState> {
  PhotoController(this.target);
  final PhotoTarget target;
  int _generation = 0;

  @override
  PhotoEditorState build() {
    _generation++;
    _watchActor(ref, target);
    return const PhotoEditorState();
  }

  String _actor() {
    final actor = ref.read(photoActorProvider(target));
    if (actor == null) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'Tu acceso a esta foto ya no está disponible.',
      );
    }
    return actor;
  }

  Future<void> select(PhotoSource source, {bool darkTheme = true}) => _prepare(
    (repository, actor, draft) => repository.pick(source, darkTheme: darkTheme),
  );

  Future<void> editCurrent({bool darkTheme = true}) => _prepare(
    (repository, actor, draft) => repository.editCurrent(
      actor,
      target,
      draft: draft,
      darkTheme: darkTheme,
    ),
  );

  Future<void> _prepare(
    Future<Uint8List?> Function(PhotoRepository, String, Uint8List?) action,
  ) async {
    if (state.busy) return;
    final generation = _generation;
    final previous = state.draft;
    state = PhotoEditorState(draft: previous, busy: true);
    try {
      final actor = _actor();
      final bytes = await action(
        ref.read(photoRepositoryProvider),
        actor,
        previous,
      );
      if (!ref.mounted ||
          generation != _generation ||
          ref.read(photoActorProvider(target)) != actor) {
        return;
      }
      state = PhotoEditorState(draft: bytes ?? previous);
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = PhotoEditorState(draft: previous, error: failureMessage(error));
      }
    }
  }

  Future<bool> save({bool remove = false}) async {
    if (state.busy || (!remove && state.draft == null)) return false;
    final generation = _generation;
    final draft = state.draft;
    state = PhotoEditorState(draft: draft, busy: true);
    try {
      final actor = _actor();
      final repository = ref.read(photoRepositoryProvider);
      if (remove) {
        await repository.remove(actor, target);
      } else {
        await repository.upload(actor, target, draft!);
      }
      if (!ref.mounted ||
          generation != _generation ||
          ref.read(photoActorProvider(target)) != actor) {
        return false;
      }
      state = const PhotoEditorState();
      ref.invalidate(photoProvider(target));
      ref.invalidate(photoAccessProvider(target));
      if (target.kind == PhotoKind.account) {
        for (final memberTarget in repository.cache.memberTargets(
          actor,
          actor,
        )) {
          ref.read(photoRefreshProvider)(memberTarget);
        }
      }
      return true;
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = PhotoEditorState(draft: draft, error: failureMessage(error));
      }
      return false;
    }
  }
}
