import 'package:flutter/material.dart';
import '../../../design_system/design_system.dart';
import '../../../models/group_member.dart';

String roleLabel(GroupRole role) => switch (role) {
  GroupRole.owner => 'Propietario',
  GroupRole.admin => 'Administrador',
  GroupRole.member => 'Miembro',
};

// Editorial opening shared by the group index and its detail; visual data only.
class GroupOpening extends StatelessWidget {
  const GroupOpening({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.footer,
  });
  final String eyebrow;
  final String title;
  final String description;
  final Widget? footer;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final type = AppTypography.of(context);
    return AppReveal(
      child: AppHeroPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: type.labelSmall.copyWith(color: colors.onHero),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: type.displayLarge.copyWith(color: colors.onHero),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              description,
              style: type.bodyLarge.copyWith(color: colors.onHero),
            ),
            if (footer != null) ...[
              const SizedBox(height: AppSpacing.xl),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
