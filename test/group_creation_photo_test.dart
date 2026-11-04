import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_management_providers.dart';
import 'package:bote_parroquial/features/photos/providers/photo_providers.dart';
import 'package:bote_parroquial/models/group_input.dart';
import 'package:bote_parroquial/models/photo_target.dart';
import 'package:bote_parroquial/repositories/group_management_repository.dart';
import 'package:bote_parroquial/repositories/photo_repository.dart';
import 'package:bote_parroquial/services/photo_service.dart';
import 'auth_flow_test.dart' as auth;
import 'full_product_progress_test.dart' as product;

class Photos extends Fake implements PhotoService {
  int writes = 0, reads = 0;
  bool fail = true;
  @override
  Future<PhotoAccess> access(String actorUid, PhotoTarget target) async {
    reads++;
    return const PhotoAccess(canRead: true, canEdit: true);
  }

  @override
  Future<void> upload(
    String actorUid,
    PhotoTarget target,
    Uint8List image,
  ) async {
    writes++;
    if (fail) throw StateError('offline');
  }
}

class Picker extends Fake implements PhotoPickerService {
  Uint8List? result = Uint8List.fromList([255, 216, 255]);
  @override
  Future<Uint8List?> pick(
    PhotoSource source, {
    bool darkTheme = true,
    bool panoramic = false,
  }) async {
    expect(panoramic, isTrue);
    return result;
  }
}

void main() {
  test(
    'Foto local sin acceso remoto; fallo conserva grupo y reintento no duplica el alta',
    () async {
      final groups = product.ManagedGroups();
      final profiles = product.Profiles();
      final photos = Photos(), picker = Picker();
      final scope = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(auth.alice)),
          userProfileRepositoryProvider.overrideWithValue(profiles),
          groupManagementRepositoryProvider.overrideWithValue(
            GroupManagementRepository(groups),
          ),
          photoRepositoryProvider.overrideWithValue(
            PhotoRepository(photos, picker),
          ),
          photoRefreshProvider.overrideWithValue((_) {}),
        ],
      );
      final keep = scope.listen(
        groupManagementControllerProvider('new'),
        (_, _) {},
      );
      final draftKeep = scope.listen(groupDraftPhotoProvider('new'), (_, _) {});
      addTearDown(() async {
        keep.close();
        draftKeep.close();
        scope.dispose();
        await groups.updates.close();
        await groups.changes.close();
      });
      await scope.read(authStateProvider.future);
      final draft = scope.read(groupDraftPhotoProvider('new').notifier);
      await draft.select(PhotoSource.gallery, darkTheme: true);
      expect(photos.reads, 0);
      expect(photos.writes, 0);
      picker.result = null;
      await draft.select(PhotoSource.camera, darkTheme: true);
      expect(scope.read(groupDraftPhotoProvider('new')).draft, isNotNull);
      final controller = scope.read(
        groupManagementControllerProvider('new').notifier,
      );
      Future<bool> save() => controller.save(
        name: 'Grupo',
        description: '',
        creation: const GroupInput(
          name: 'Grupo',
          description: '',
          currency: 'EUR',
          timeZone: 'Europe/Madrid',
          createOwnerPerson: true,
        ),
      );
      expect(await save(), isFalse);
      expect(controller.groupCreated, isTrue);
      expect(groups.writes, 1);
      expect(
        scope.read(groupManagementControllerProvider('new')).error.toString(),
        contains('El grupo ya está creado'),
      );
      photos.fail = false;
      expect(await save(), isTrue);
      expect(groups.writes, 1);
      expect(photos.writes, 2);
    },
  );
}
