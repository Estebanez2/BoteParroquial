import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../models/group.dart';
import '../../../models/group_input.dart';
import '../../../repositories/group_management_repository.dart';
import '../../../services/firestore_group_management_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../persons/providers/person_providers.dart';
import '../../photos/providers/photo_providers.dart';
import '../../../models/photo_target.dart';

final groupManagementRepositoryProvider = Provider<GroupManagementRepository>(
  (ref) => GroupManagementRepository(
    FirestoreGroupManagementService(ref.watch(firestoreProvider)),
  ),
);
final groupCurrenciesProvider = Provider(
  (ref) => GroupManagementRepository.currencies,
);
final groupTimeZonesProvider = Provider(
  (ref) => GroupManagementRepository.timeZones,
);
final canEditGroupProvider = Provider.autoDispose.family<bool, String>(
  (ref, id) => ref.watch(canManagePersonsProvider(id)),
);
final groupManagementControllerProvider = NotifierProvider.autoDispose
    .family<GroupManagementController, AsyncValue<void>, String>(
      GroupManagementController.new,
    );

class GroupManagementController extends Notifier<AsyncValue<void>> {
  GroupManagementController(this.groupId);
  final String groupId;
  String? _createdUid;
  bool get groupCreated => _createdUid != null;
  @override
  AsyncValue<void> build() => const AsyncData(null);
  String newId() => ref.read(groupManagementRepositoryProvider).newId();
  String? validateName(String? value) =>
      GroupManagementRepository.nameError(value);
  String? validateDescription(String? value) =>
      GroupManagementRepository.descriptionError(value);
  Future<bool> save({
    required String name,
    required String description,
    Group? original,
    GroupInput? creation,
  }) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final user = ref.read(authStateProvider).asData?.value;
      if (user == null ||
          (_createdUid != null && _createdUid != user.uid) ||
          (original != null &&
              (original.id != groupId ||
                  !ref.read(canEditGroupProvider(groupId))))) {
        throw const AppFailure(
          FailureCode.permissionDenied,
          'Ya no tienes permiso para guardar este grupo.',
        );
      }
      final repository = ref.read(groupManagementRepositoryProvider);
      if (original != null) {
        await repository.update(original, user.uid, name, description);
      } else {
        if (creation == null) {
          throw const AppFailure(
            FailureCode.invalidData,
            'Completa los datos del grupo.',
          );
        }
        if (_createdUid == null) {
          final profile = await ref.read(userProfileProvider.future);
          if (!ref.mounted ||
              profile?.uid != user.uid ||
              ref.read(authStateProvider).asData?.value?.uid != user.uid) {
            throw const AppFailure(
              FailureCode.permissionDenied,
              'Tu sesión ha cambiado. Abre el formulario de nuevo.',
            );
          }
          await repository.create(
            groupId,
            user.uid,
            profile!.displayName,
            creation,
          );
          _createdUid = user.uid;
        }
        if (!ref.mounted ||
            ref.read(authStateProvider).asData?.value?.uid != user.uid) {
          return false;
        }
        final photo = ref.read(groupDraftPhotoProvider(groupId)).draft;
        if (photo != null) {
          try {
            await ref
                .read(photoRepositoryProvider)
                .upload(user.uid, PhotoTarget.group(groupId), photo);
            if (!ref.mounted ||
                ref.read(authStateProvider).asData?.value?.uid != user.uid) {
              return false;
            }
            ref.read(photoRefreshProvider)(PhotoTarget.group(groupId));
          } catch (error) {
            throw AppFailure(
              error is AppFailure ? error.code : FailureCode.unknown,
              'El grupo ya está creado, pero no se pudo guardar la foto. Reintenta la subida; no se creará otro grupo. ${failureMessage(error)}',
            );
          }
        }
      }
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return false;
    }
  }
}

final groupDraftPhotoProvider = NotifierProvider.autoDispose
    .family<GroupDraftPhotoController, PhotoEditorState, String>(
      GroupDraftPhotoController.new,
    );

/// Local image draft: no membership or Storage access before the group exists.
class GroupDraftPhotoController extends Notifier<PhotoEditorState> {
  GroupDraftPhotoController(this.groupId);
  final String groupId;
  int _generation = 0;
  @override
  PhotoEditorState build() {
    _generation++;
    ref.watch(authStateProvider.select((value) => value.asData?.value?.uid));
    return const PhotoEditorState();
  }

  Future<void> select(PhotoSource source, {required bool darkTheme}) =>
      _prepare(
        (previous) => ref
            .read(photoRepositoryProvider)
            .pick(
              source,
              target: PhotoTarget.group(groupId),
              darkTheme: darkTheme,
            ),
      );
  Future<void> edit({required bool darkTheme}) => _prepare(
    (previous) async => previous == null
        ? null
        : ref
              .read(photoRepositoryProvider)
              .editDraft(previous, panoramic: true, darkTheme: darkTheme),
  );
  Future<void> _prepare(
    Future<Uint8List?> Function(Uint8List?) operation,
  ) async {
    if (state.busy) return;
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null) return;
    final generation = _generation;
    final previous = state.draft;
    state = PhotoEditorState(draft: previous, busy: true);
    try {
      final bytes = await operation(previous);
      if (!ref.mounted ||
          generation != _generation ||
          ref.read(authStateProvider).asData?.value?.uid != uid) {
        return;
      }
      state = PhotoEditorState(draft: bytes ?? previous);
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = PhotoEditorState(draft: previous, error: failureMessage(error));
      }
    }
  }

  void clear() {
    if (!state.busy) state = const PhotoEditorState();
  }
}
