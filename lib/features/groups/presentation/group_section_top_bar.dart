import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/design_system.dart';
import '../../../models/photo_target.dart';
import '../../photos/presentation/photo_view.dart';
import '../providers/group_providers.dart';

class GroupSectionTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const GroupSectionTopBar({
    super.key,
    required this.groupId,
    required this.title,
    this.leading,
  });
  final String groupId, title;
  final Widget? leading;
  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.topBarHeight);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(currentMembershipProvider(groupId));
    final group = ref.watch(groupProvider(groupId)).asData?.value;
    return AppTopBar(
      title: title,
      leading: leading,
      actions: [
        if (member != null && group != null)
          PhotoView(
            target: PhotoTarget.group(groupId),
            builder: (_, image, loading) => AppCompactIdentity(
              name: group.name,
              image: image,
              loading: loading,
            ),
          ),
      ],
    );
  }
}
