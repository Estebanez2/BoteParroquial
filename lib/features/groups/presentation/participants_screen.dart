import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/offline/offline_mode.dart';
import '../../../design_system/design_system.dart';
import 'group_access_body.dart';
import 'group_bottom_navigation.dart';
import 'group_section_top_bar.dart';

class ParticipantsScreen extends ConsumerWidget {
  const ParticipantsScreen({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    maxWidth: AppSpacing.readingMax,
    appBar: GroupSectionTopBar(
      groupId: groupId,
      title: 'Participantes',
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver al resumen',
        onPressed: () => context.go('/groups/$groupId'),
      ),
    ),
    bottomNavigation: GroupBottomNavigation(groupId: groupId, selectedIndex: 2),
    child: GroupAccessBody(
      groupId: groupId,
      builder: (group, membership) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cada persona, su lugar.',
            style: AppTypography.of(context).headingLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Consulta las personas del bote y las cuentas que tienen acceso al grupo.',
            style: AppTypography.of(context).bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (!ref.watch(offlineReadOnlyProvider)) ...[
            AppButton(
              label: 'Invitar al grupo',
              leadingIcon: Icons.person_add_alt_1_rounded,
              fullWidth: true,
              onPressed: () => context.push('/groups/$groupId/invitations'),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppNavigationTile(
            label: 'Ver personas',
            description:
                'Personas del bote, aportaciones y cuotas. Pueden existir sin cuenta.',
            icon: Icons.people_alt_outlined,
            tone: AppTone.secondary,
            onTap: () => context.push('/groups/$groupId/persons'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppNavigationTile(
            label: 'Ver miembros',
            description: 'Cuentas con acceso, roles, vínculos e invitaciones.',
            icon: Icons.manage_accounts_outlined,
            tone: AppTone.tertiary,
            onTap: () => context.push('/groups/$groupId/members'),
          ),
        ],
      ),
    ),
  );
}
