import 'package:flutter/material.dart';
import '../../../design_system/design_system.dart';
import '../../../models/group.dart';
import '../../../models/group_member.dart';
import 'group_widgets.dart';

class GroupIdentityHeader extends StatelessWidget {
  const GroupIdentityHeader({
    super.key,
    required this.group,
    required this.membership,
  });
  final Group group;
  final GroupMember membership;
  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NUESTRO GRUPO',
          style: t.labelSmall.copyWith(
            color: AppColors.of(context).textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(group.name, style: t.displayLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppBadge(
              roleLabel(membership.role),
              tone: AppTone.primary,
              icon: membership.role == GroupRole.owner
                  ? Icons.workspace_premium_outlined
                  : Icons.people_outline,
            ),
            AppBadge(group.currency),
          ],
        ),
        if (group.description?.isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(group.description!, style: t.bodyMedium),
        ],
      ],
    );
    return AppReveal(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
              constraints.maxWidth < AppSpacing.coverSmall * 3) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCover(name: group.name),
                const SizedBox(height: AppSpacing.lg),
                text,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCover(name: group.name),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: text),
            ],
          );
        },
      ),
    );
  }
}
