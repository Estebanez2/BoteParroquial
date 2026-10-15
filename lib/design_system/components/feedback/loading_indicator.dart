import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.label = 'Cargando',
    this.size = AppSpacing.iconLarge,
    this.color,
  });
  final String label;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    liveRegion: true,
    child: SizedBox(
      width: size,
      height: size,
      child: MediaQuery.disableAnimationsOf(context)
          ? Icon(
              Icons.hourglass_empty_rounded,
              size: size,
              color: color ?? AppColors.of(context).primary,
            )
          : CircularProgressIndicator(
              strokeWidth: 2,
              color: color ?? AppColors.of(context).primary,
            ),
    ),
  );
}
