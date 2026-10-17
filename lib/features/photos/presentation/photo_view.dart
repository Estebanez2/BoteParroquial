import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/design_system.dart';
import '../../../models/photo_target.dart';
import '../providers/photo_providers.dart';
import 'photo_editor_screen.dart';

/// Authenticated image through the account-scoped private cache and providers.
class PhotoView extends ConsumerStatefulWidget {
  const PhotoView({super.key, required this.target, required this.builder});
  final PhotoTarget target;
  final Widget Function(BuildContext, ImageProvider?, bool loading) builder;
  @override
  ConsumerState<PhotoView> createState() => _PhotoViewState();
}

class _PhotoViewState extends ConsumerState<PhotoView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(photoRefreshProvider)(widget.target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(photoPresentationProvider(widget.target));
    final bytes = value.bytes;
    return widget.builder(
      context,
      bytes == null ? null : MemoryImage(bytes),
      value.loading,
    );
  }
}

class PhotoAvatar extends StatelessWidget {
  const PhotoAvatar({
    super.key,
    required this.target,
    required this.name,
    this.size = AppAvatarSize.medium,
    this.interactive = false,
  });
  final PhotoTarget target;
  final String name;
  final AppAvatarSize size;
  final bool interactive;
  @override
  Widget build(BuildContext context) => PhotoView(
    target: target,
    builder: (context, image, loading) {
      final avatar = AppAvatar(
        name: name,
        size: size,
        image: image,
        loading: loading,
      );
      if (!interactive) return avatar;
      return Semantics(
        button: true,
        label: 'Foto de $name',
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: () => showPhotoEditor(context, target: target, name: name),
          child: avatar,
        ),
      );
    },
  );
}

class PhotoCover extends StatelessWidget {
  const PhotoCover({
    super.key,
    required this.groupId,
    required this.name,
    this.interactive = false,
  });
  final String groupId, name;
  final bool interactive;
  @override
  Widget build(BuildContext context) => PhotoView(
    target: PhotoTarget.group(groupId),
    builder: (context, image, loading) {
      final cover = AppCover(name: name, image: image, loading: loading);
      if (!interactive) return cover;
      return Semantics(
        button: true,
        label: 'Imagen del grupo $name',
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: () => showPhotoEditor(
            context,
            target: PhotoTarget.group(groupId),
            name: name,
          ),
          child: cover,
        ),
      );
    },
  );
}
