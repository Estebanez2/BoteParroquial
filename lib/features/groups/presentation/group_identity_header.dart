import 'package:flutter/material.dart';
import '../../../design_system/design_system.dart';
import '../../../models/group.dart';
import '../../../models/group_member.dart';
import 'group_widgets.dart';
import '../../photos/presentation/photo_view.dart';

class GroupIdentityHeader extends StatelessWidget {
  const GroupIdentityHeader({
    super.key,
    required this.group,
    required this.membership,
    this.panoramic = false,
  });
  final Group group;
  final GroupMember membership;
  final bool panoramic;
  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(group.name, style: panoramic ? t.displayLarge : t.headingSmall),
        if (group.description?.isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            group.description!,
            style: t.bodyMedium.copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppBadge(roleLabel(membership.role), tone: AppTone.primary),
            AppBadge(group.currency),
          ],
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (panoramic) ...[
          PhotoCover(
            groupId: group.id,
            name: group.name,
            interactive: true,
            panoramic: true,
            edgeToEdge: true,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xl,
              AppSpacing.page,
              0,
            ),
            child: identity,
          ),
        ] else
          identity,
      ],
    );
  }
}
