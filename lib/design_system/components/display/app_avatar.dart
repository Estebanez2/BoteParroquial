import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

enum AppAvatarSize { small, medium, large }

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.image,
    this.size = AppAvatarSize.medium,
    this.showIndicator = false,
    this.indicatorLabel = 'Activo',
  });
  final String name;
  final ImageProvider? image;
  final AppAvatarSize size;
  final bool showIndicator;
  final String indicatorLabel;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final diameter = switch (size) {
      AppAvatarSize.small => AppSpacing.avatarSmall,
      AppAvatarSize.medium => AppSpacing.avatarMedium,
      AppAvatarSize.large => AppSpacing.avatarLarge,
    };
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final initials = words.isEmpty
        ? '?'
        : [
            words.first,
            if (words.length > 1) words.last,
          ].map((word) => word.characters.first).join().toUpperCase();
    return Semantics(
      label: showIndicator ? '$name, $indicatorLabel' : name,
      excludeSemantics: true,
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: Stack(
          children: [
            CircleAvatar(
              radius: diameter / 2,
              backgroundColor: c.primaryContainer,
              foregroundColor: c.primary,
              foregroundImage: image,
              onForegroundImageError: image == null
                  ? null
                  : (error, stackTrace) {},
              child: Text(
                initials,
                style: size == AppAvatarSize.large
                    ? AppTypography.of(context).headingSmall
                    : AppTypography.of(
                        context,
                      ).labelMedium.copyWith(color: c.primary),
              ),
            ),
            if (showIndicator)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: AppSpacing.md,
                  height: AppSpacing.md,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.success,
                    border: Border.all(color: c.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
