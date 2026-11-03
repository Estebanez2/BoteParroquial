import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'app_skeleton.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.label = 'Cargando',
    this.size,
    this.color,
  });
  final String label;
  final double? size;
  final Color? color;
  @override
  Widget build(BuildContext context) => size == null
      ? AppSkeleton(label: label)
      : AppShimmer(
          label: label,
          color: color,
          child: Container(
            width: size,
            height: AppSpacing.sm,
            decoration: BoxDecoration(
              color: color ?? AppColors.of(context).surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
          ),
        );
}
