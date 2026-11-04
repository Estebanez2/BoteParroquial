import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../buttons/app_button.dart';
import '../cards/app_card.dart';

/// Compact, persistent source label. The content below remains usable.
class AppReadOnlyBanner extends StatelessWidget {
  const AppReadOnlyBanner({
    super.key,
    required this.dateLabel,
    required this.onExit,
  });

  final String dateLabel;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label:
                  'Las cifras corresponden a ese instante; las fotos son las de caché.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('COPIA GUARDADA · SOLO LECTURA', style: type.labelSmall),
                  Text(dateLabel, style: type.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: AppButton(
              label: 'Datos actuales',
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.compact,
              onPressed: onExit,
            ),
          ),
        ],
      ),
    );
  }
}
