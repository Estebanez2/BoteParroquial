import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../feedback/app_skeleton.dart';

/// Compact non-interactive identity for the trailing side of a section toolbar.
class AppCompactIdentity extends StatelessWidget {
  const AppCompactIdentity({
    super.key,
    required this.name,
    this.image,
    this.loading = false,
  });
  final String name;
  final ImageProvider? image;
  final bool loading;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: AppSpacing.ornamentSize),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.of(context).labelSmall,
            textAlign: TextAlign.end,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadius.control,
          child: SizedBox.square(
            dimension: AppSpacing.avatarSmall,
            child: loading
                ? AppShimmer(
                    child: ColoredBox(
                      color: AppColors.of(context).surfaceVariant,
                    ),
                  )
                : image != null
                ? Image(
                    image: image!,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  )
                : ColoredBox(
                    color: AppColors.of(context).surfaceVariant,
                    child: Icon(
                      Icons.photo_outlined,
                      size: AppSpacing.icon,
                      color: AppColors.of(context).textSecondary,
                    ),
                  ),
          ),
        ),
      ],
    ),
  );
}
