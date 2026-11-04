import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../feedback/app_skeleton.dart';

/// A group cover with a bundled visual placeholder when no image is available.
class AppCover extends StatelessWidget {
  const AppCover({
    super.key,
    required this.name,
    this.image,
    this.large = false,
    this.loading = false,
    this.panoramic = false,
    this.edgeToEdge = false,
    this.titleOnImage = false,
  });
  final String name;
  final ImageProvider? image;
  final bool large;
  final bool loading;
  final bool panoramic, edgeToEdge;
  final bool titleOnImage;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fallback = DecoratedBox(
      decoration: BoxDecoration(gradient: AppGradients.hero(context)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FittedBox(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: AppSpacing.xxxl,
                  color: c.onHero,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Sin foto',
                  style: AppTypography.of(
                    context,
                  ).labelLarge.copyWith(color: c.onHero),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final cover = Container(
      width: panoramic
          ? double.infinity
          : large
          ? AppSpacing.coverLarge
          : AppSpacing.coverSmall,
      height: panoramic
          ? null
          : large
          ? AppSpacing.coverLarge
          : AppSpacing.coverSmall,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.primaryContainer,
        borderRadius: edgeToEdge ? BorderRadius.zero : AppRadius.control,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          image == null
              ? (loading
                    ? const AppShimmer(
                        label: 'Cargando portada',
                        child: SizedBox.expand(child: AppSkeletonBlock()),
                      )
                    : fallback)
              : Image(
                  image: image!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => fallback,
                ),
          if (titleOnImage)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      c.imageScrim.withValues(alpha: .45),
                      c.imageScrim.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.xxxl,
                    AppSpacing.page,
                    AppSpacing.lg,
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: c.imageScrim.withValues(alpha: .28),
                        borderRadius: AppRadius.control,
                        border: Border.all(
                          color: c.onImage.withValues(alpha: .18),
                        ),
                      ),
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.of(
                          context,
                        ).headingSmall.copyWith(color: c.onImage),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    return Semantics(
      label: 'Imagen de $name',
      image: true,
      child: panoramic
          ? AspectRatio(aspectRatio: AppSpacing.coverAspectRatio, child: cover)
          : cover,
    );
  }
}
