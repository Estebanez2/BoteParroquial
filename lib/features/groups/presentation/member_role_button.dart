import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/design_system.dart';
import '../../../models/group_member.dart';
import '../providers/member_role_providers.dart';

class MemberRoleButton extends ConsumerWidget {
  const MemberRoleButton({super.key, required this.member});
  final GroupMember member;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(nextMemberRoleProvider((member.groupId, member)));
    if (next == null) return const SizedBox.shrink();
    final promoting = next == GroupRole.admin;
    return AppButton(
      label: promoting ? 'Hacer administrador' : 'Pasar a miembro',
      variant: AppButtonVariant.ghost,
      leadingIcon: Icons.admin_panel_settings_outlined,
      onPressed:
          ref.watch(memberRoleControllerProvider(member.groupId)).isLoading
          ? null
          : () async {
              final controller = ref.read(
                memberRoleControllerProvider(member.groupId).notifier,
              );
              final confirmed = await AppDialog.show(
                context,
                title: promoting
                    ? '¿Dar permisos de administrador?'
                    : '¿Quitar permisos de administrador?',
                description: promoting
                    ? '${member.displayName} podrá gestionar personas, dinero, invitaciones y otros administradores. No podrá cambiar al propietario.'
                    : '${member.displayName} seguirá en el grupo como miembro. Se conservan su persona, sus fotos y su historial.',
                confirmLabel: promoting
                    ? 'Confirmar administrador'
                    : 'Confirmar miembro',
              );
              if (confirmed && context.mounted) {
                await controller.changeRole(member, next);
              }
            },
    );
  }
}
