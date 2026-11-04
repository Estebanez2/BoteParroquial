import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../display/app_atmosphere.dart';
import 'app_hero_panel.dart';
import '../display/app_logo.dart';

class AppWelcomePanel extends StatelessWidget {
  const AppWelcomePanel({
    super.key,
    required this.title,
    required this.description,
  });
  final String title, description;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context), t = AppTypography.of(context);
    return AppHeroPanel(
      child: Stack(
        children: [
          const Positioned.fill(child: AppAtmosphere()),
          const Positioned.fill(child: AppLogoBackdrop()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: AppSpacing.coverLarge + AppSpacing.lg,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: AppSpacing.coverLarge,
                        height: AppSpacing.coverLarge,
                        decoration: BoxDecoration(
                          color: c.primaryContainer,
                          borderRadius: AppRadius.control,
                          border: Border.all(
                            color: c.primary,
                            width: AppSpacing.actionBorder,
                          ),
                        ),
                        child: const AppLogo(size: AppSpacing.coverLarge),
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.coverSmall,
                      top: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: c.tertiaryContainer,
                          borderRadius: AppRadius.control,
                          border: Border.all(color: c.tertiary),
                        ),
                        child: Icon(
                          Icons.favorite_border_rounded,
                          color: c.tertiary,
                        ),
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.coverSmall,
                      bottom: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: c.secondaryContainer,
                          borderRadius: AppRadius.control,
                          border: Border.all(color: c.secondary),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: c.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'LO NUESTRO, EN COMÚN',
                style: t.labelSmall.copyWith(color: c.onHero),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: t.displayLarge.copyWith(color: c.onHero)),
              const SizedBox(height: AppSpacing.lg),
              Text(description, style: t.bodyLarge.copyWith(color: c.onHero)),
            ],
          ),
        ],
      ),
    );
  }
}
