import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/design_system.dart';
import '../../groups/presentation/group_access_body.dart';
import 'persons_section.dart';

class PersonsScreen extends StatelessWidget {
  const PersonsScreen({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context) => AppScaffold(
    maxWidth: AppSpacing.readingMax,
    appBar: AppTopBar(
      title: 'Personas',
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver al resumen',
        onPressed: () => context.go('/groups/$groupId'),
      ),
    ),
    child: GroupAccessBody(
      groupId: groupId,
      builder: (group, membership) => PersonsSection(groupId: groupId),
    ),
  );
}
