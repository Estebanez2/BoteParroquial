import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'app_hero_panel.dart';
import '../buttons/app_button.dart';
import '../display/app_badge.dart';

class AppThemePreview extends StatelessWidget {
  const AppThemePreview({super.key, required this.theme});
  final ThemeData theme;
  @override
  Widget build(BuildContext context) => Theme(
    data: theme,
    child: Builder(
      builder: (context) {
        final c = AppColors.of(context), t = AppTypography.of(context);
        return Semantics(
          label: 'Vista previa de apariencia, sin acciones reales',
          child: ExcludeFocus(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(color: c.background),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppHeroPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Tu comunidad', style: t.headingMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Así se verán los textos, los paneles y las acciones.',
                          style: t.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            AppBadge('Principal', tone: AppTone.primary),
                            AppBadge('Complementario', tone: AppTone.secondary),
                            AppBadge('Acento', tone: AppTone.tertiary),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(label: 'Acción principal', onPressed: () {}),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: 'Acción secundaria',
                          variant: AppButtonVariant.secondary,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
