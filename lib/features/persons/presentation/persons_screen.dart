import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/design_system.dart';
import '../../groups/presentation/group_access_body.dart';
import '../../groups/presentation/group_bottom_navigation.dart';
import 'persons_section.dart';
import '../../groups/presentation/group_section_top_bar.dart';

class PersonsScreen extends StatelessWidget {
  const PersonsScreen({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context) => AppScaffold(
    maxWidth: AppSpacing.readingMax,
    bottomNavigation: GroupBottomNavigation(groupId: groupId, selectedIndex: 2),
    appBar: GroupSectionTopBar(
      groupId: groupId,
      title: 'Personas',
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver a participantes',
        onPressed: () => context.go('/groups/$groupId/participants'),
      ),
    ),
    child: GroupAccessBody(
      groupId: groupId,
      builder: (group, membership) => PersonsSection(groupId: groupId),
    ),
  );
}
