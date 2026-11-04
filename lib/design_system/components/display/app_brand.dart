import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'app_logo.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Shared application identity, using the supplied logo without recoloring it.
class AppBrand extends StatelessWidget {
  const AppBrand({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogo(),
        if (!compact) ...[
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Bote'),
                  TextSpan(
                    text: 'Parroquial',
                    style: TextStyle(color: c.primary),
                  ),
                ],
              ),
              style: AppTypography.of(context).headingSmall,
            ),
          ),
        ],
      ],
    );
  }
}
