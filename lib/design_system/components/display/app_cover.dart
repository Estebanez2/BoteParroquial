import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// A group cover; the caller can supply a photo when uploads become available.
class AppCover extends StatelessWidget {
  const AppCover({
    super.key,
    required this.name,
    this.image,
    this.large = false,
  });
  final String name;
  final ImageProvider? image;
  final bool large;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final initials = words.isEmpty
        ? '?'
        : words.map((w) => w.characters.first).join().toUpperCase();
    final fallback = DecoratedBox(
      decoration: BoxDecoration(gradient: AppGradients.hero(context)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FittedBox(
            child: Text(
              initials,
              style: AppTypography.of(
                context,
              ).displayLarge.copyWith(color: c.onHero),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      label: 'Imagen de $name',
      image: true,
      child: Container(
        width: large ? AppSpacing.coverLarge : AppSpacing.coverSmall,
        height: large ? AppSpacing.coverLarge : AppSpacing.coverSmall,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          border: Border.all(color: c.outline.withValues(alpha: .5)),
        ),
        child: image == null
            ? fallback
            : Image(
                image: image!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => fallback,
              ),
      ),
    );
  }
}
