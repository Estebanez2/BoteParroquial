import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/photos/presentation/photo_editor_screen.dart';
import 'package:bote_parroquial/features/photos/providers/photo_providers.dart';
import 'package:bote_parroquial/models/auth_user.dart';
import 'package:bote_parroquial/models/photo_target.dart';
import 'package:bote_parroquial/repositories/photo_repository.dart';
import 'package:bote_parroquial/services/device_photo_picker_service.dart';
import 'package:bote_parroquial/services/photo_service.dart';
import 'package:bote_parroquial/services/photo_cache_service.dart';
import 'package:bote_parroquial/features/photos/presentation/photo_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

class _Photos implements PhotoService {
  bool allowed = true;
  Uint8List? stored;
  final writes = <PhotoTarget>[];
  @override
  Future<PhotoAccess> access(String actorUid, PhotoTarget target) async =>
      PhotoAccess(canRead: true, canEdit: allowed);
  @override
  Future<Uint8List?> read(String actorUid, PhotoTarget target) async => stored;
  @override
  Future<void> upload(
    String actorUid,
    PhotoTarget target,
    Uint8List bytes,
  ) async {
    writes.add(target);
    stored = bytes;
  }

  @override
  Future<void> remove(String actorUid, PhotoTarget target) async {
    writes.add(target);
    stored = null;
  }
}

class _Picker implements PhotoPickerService {
  Future<Uint8List?> next = Future.value(null);
  Uint8List? lastEdited;
  @override
  Future<Uint8List?> pick(PhotoSource source, {bool darkTheme = true}) => next;
  @override
  Future<Uint8List?> edit(Uint8List bytes, {bool darkTheme = true}) {
    lastEdited = bytes;
    return next;
  }
}

class _VersionPhotos extends _Photos implements VersionedPhotoService {
  int downloads = 0;
  Completer<PhotoReadResult>? pending;
  final started = Completer<void>();
  @override
  Future<PhotoReadResult> readVersion(
    String actorUid,
    PhotoTarget target,
    String? version,
  ) async {
    downloads++;
    if (!started.isCompleted) started.complete();
    if (pending != null) return pending!.future;
    return PhotoReadResult(
      bytes: version == 'v1' ? null : stored,
      version: 'v1',
      notModified: version == 'v1',
    );
  }
}

const _target = PhotoTarget.account('alice');
const _alice = AuthUser(uid: 'alice', displayName: 'DEMO Alice');

void main() {
  test(
    'Private disk/memory cache reuses unchanged bytes and clears account scope',
    () async {
      final folder = await Directory.systemTemp.createTemp('bote_photo_test_');
      addTearDown(() => folder.delete(recursive: true));
      final cache = PhotoCacheService(directory: () async => folder);
      final service = _VersionPhotos()..stored = Uint8List.fromList([1, 2, 3]);
      final repo = PhotoRepository(service, _Picker(), cache: cache);
      final first = await repo.read('alice', _target);
      expect(identical(await repo.read('alice', _target), first), isTrue);
      expect(service.downloads, 1);
      cache.stale('alice', _target);
      expect((await repo.watch('alice', _target).toList()).length, 1);
      expect(service.downloads, 2);
      expect(identical(cache.peek('alice', _target)?.bytes, first), isTrue);
      final restored = PhotoCacheService(directory: () async => folder);
      expect((await restored.load('alice', _target))?.bytes, first);
      expect(await restored.load('bob', _target), isNull);
      await cache.clearAccount('alice');
      expect(cache.peek('alice', _target), isNull);
      expect(
        await PhotoCacheService(
          directory: () async => folder,
        ).load('alice', _target),
        isNull,
      );
    },
  );

  test(
    'A delayed download cannot restore an account cache after logout',
    () async {
      final service = _VersionPhotos()..pending = Completer<PhotoReadResult>();
      final repo = PhotoRepository(service, _Picker());
      final reading = repo.watch('alice', _target).toList();
      await service.started.future;
      await repo.cache.clearAccount('alice');
      service.pending!.complete(
        PhotoReadResult(bytes: Uint8List.fromList([1]), version: 'v1'),
      );
      expect(await reading, isEmpty);
      expect(repo.cache.peek('alice', _target), isNull);
    },
  );

  testWidgets('Remount and background validation retain the displayed photo', (
    tester,
  ) async {
    final service = _VersionPhotos()
      ..stored = image.encodePng(image.Image(width: 10, height: 10));
    final repo = PhotoRepository(service, _Picker());
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    final hasImages = <bool>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(_alice)),
          photoRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: visible,
            builder: (context, show, _) => show
                ? PhotoView(
                    target: _target,
                    builder: (context, photo, loading) {
                      hasImages.add(photo != null);
                      return Text(photo == null ? 'initials' : 'image');
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    visible.value = false;
    await tester.pump();
    hasImages.clear();
    visible.value = true;
    await tester.pump();
    expect(hasImages, isNotEmpty);
    expect(hasImages.every((hasPhoto) => hasPhoto), isTrue);
    service.pending = Completer<PhotoReadResult>();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PhotoView)),
    );
    container.read(photoRefreshProvider)(_target);
    await tester.pump();
    expect(find.text('image'), findsOneWidget);
    service.pending!.complete(
      const PhotoReadResult(notModified: true, version: 'v1'),
    );
    await tester.pumpAndSettle();
    expect(find.text('initials'), findsNothing);
  });
  test('Photo scope and permission denials never write storage', () async {
    final service = _Photos();
    final repository = PhotoRepository(service, _Picker());
    final bytes = Uint8List.fromList([1, 2, 3]);
    await expectLater(
      repository.upload('bob', _target, bytes),
      throwsA(isA<AppFailure>()),
    );
    service.allowed = false;
    await expectLater(
      repository.upload('alice', _target, bytes),
      throwsA(isA<AppFailure>()),
    );
    await expectLater(
      repository.remove('alice', _target),
      throwsA(isA<AppFailure>()),
    );
    expect(service.writes, isEmpty);
  });

  test('Photo preparation encodes bounded JPEG without source EXIF', () {
    final original = image.Image(width: 1400, height: 900);
    original.exif.imageIfd.make = 'DEMO private metadata';
    final bytes = preparePhoto(image.encodeJpg(original));
    final decoded = image.decodeJpg(bytes)!;
    expect(decoded.width, 1024);
    expect(decoded.height, lessThan(1024));
    expect(bytes.length, lessThanOrEqualTo(524288));
    expect(decoded.exif.imageIfd.make, isNull);
    expect(
      () => preparePhoto(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<AppFailure>()),
    );
  });

  testWidgets(
    'Gallery and current photo editing cancel safely and save explicitly',
    (tester) async {
      final service = _Photos();
      final picker = _Picker();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_alice)),
            photoRepositoryProvider.overrideWithValue(
              PhotoRepository(service, picker),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const PhotoEditorScreen(target: _target, name: 'DEMO Alice'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Elegir de la galería'));
      await tester.tap(find.text('Elegir de la galería'));
      await tester.pumpAndSettle();
      expect(find.text('Guardar foto'), findsNothing);
      picker.next = Future.value(
        image.encodePng(image.Image(width: 20, height: 20)),
      );
      await tester.tap(find.text('Elegir de la galería'));
      await tester.pumpAndSettle();
      expect(service.writes, isEmpty);
      await tester.ensureVisible(find.text('Guardar foto'));
      await tester.tap(find.text('Guardar foto'));
      await tester.pumpAndSettle();
      expect(service.writes, [_target]);
      final original = service.stored;
      picker.next = Future.value(null);
      await tester.ensureVisible(find.text('Editar foto actual'));
      await tester.tap(find.text('Editar foto actual'));
      await tester.pumpAndSettle();
      expect(picker.lastEdited, original);
      expect(service.stored, original);
      expect(service.writes, [_target]);
      expect(find.text('Guardar foto'), findsNothing);
      picker.next = Future.value(
        image.encodePng(image.Image(width: 12, height: 12)),
      );
      await tester.tap(find.text('Editar foto actual'));
      await tester.pumpAndSettle();
      expect(service.writes, [_target]);
      await tester.ensureVisible(find.text('Guardar foto'));
      await tester.tap(find.text('Guardar foto'));
      await tester.pumpAndSettle();
      expect(service.writes, [_target, _target]);
      ScaffoldMessenger.of(
        tester.element(find.byType(PhotoEditorScreen)),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Quitar foto'));
      await tester.tap(find.text('Quitar foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitar foto').last);
      await tester.pumpAndSettle();
      expect(service.stored, isNull);
      expect(service.writes, [_target, _target, _target]);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Changing account during selection discards old draft and delayed error',
    () async {
      final changes = StreamController<AuthUser?>.broadcast();
      addTearDown(changes.close);
      final pending = Completer<Uint8List?>();
      final picker = _Picker()..next = pending.future;
      final container = ProviderContainer.test(
        overrides: [
          authStateProvider.overrideWith((ref) => changes.stream),
          photoRepositoryProvider.overrideWithValue(
            PhotoRepository(_Photos(), picker),
          ),
        ],
      );
      container.listen(authStateProvider, (_, _) {});
      changes.add(_alice);
      await container.read(authStateProvider.future);
      container.listen(photoControllerProvider(_target), (_, _) {});
      final selecting = container
          .read(photoControllerProvider(_target).notifier)
          .select(PhotoSource.gallery);
      changes.add(const AuthUser(uid: 'bob'));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(photoControllerProvider(_target)).draft, isNull);
      pending.completeError(
        const AppFailure(FailureCode.network, 'Old account error'),
      );
      await selecting;
      expect(container.read(photoControllerProvider(_target)).error, isNull);
      expect(container.read(photoControllerProvider(_target)).draft, isNull);
    },
  );
}
