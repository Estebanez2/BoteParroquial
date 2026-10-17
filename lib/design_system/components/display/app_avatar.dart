import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

enum AppAvatarSize { small, medium, large, editor }

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.image,
    this.size = AppAvatarSize.medium,
    this.showIndicator = false,
    this.indicatorLabel = 'Activo',
    this.loading = false,
  });
  final String name;
  final ImageProvider? image;
  final AppAvatarSize size;
  final bool showIndicator;
  final String indicatorLabel;
  final bool loading;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final diameter = switch (size) {
      AppAvatarSize.small => AppSpacing.avatarSmall,
      AppAvatarSize.medium => AppSpacing.avatarMedium,
      AppAvatarSize.large => AppSpacing.avatarLarge,
      AppAvatarSize.editor => AppSpacing.avatarEditor,
    };
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final initials = words.isEmpty
        ? '?'
        : words.map((word) => word.characters.first).join().toUpperCase();
    final initialsWidget = words.isEmpty
        ? Icon(Icons.person_outline_rounded, size: diameter / 2)
        : Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: FittedBox(
              child: Text(
                initials,
                style:
                    size == AppAvatarSize.large || size == AppAvatarSize.editor
                    ? AppTypography.of(context).headingSmall
                    : AppTypography.of(
                        context,
                      ).labelMedium.copyWith(color: c.primary),
              ),
            ),
          );
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
              child: image != null
                  ? ClipOval(
                      child: Image(
                        image: image!,
                        width: diameter,
                        height: diameter,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => initialsWidget,
                      ),
                    )
                  : loading
                  ? const SizedBox.expand()
                  : initialsWidget,
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
