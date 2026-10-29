import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/group_member.dart';
import '../../../models/person.dart';
import '../../persons/providers/person_providers.dart';
import '../providers/member_link_providers.dart';

class MemberLinkButton extends ConsumerWidget {
  const MemberLinkButton({super.key, required this.member});
  final GroupMember member;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (member.groupId, member);
    final person = ref.watch(linkedPersonProvider(key));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          member.personId == null
              ? 'Sin persona vinculada'
              : 'Persona: ${person?.displayName ?? 'Cargando vínculo…'}',
          style: AppTypography.of(context).bodySmall,
        ),
        if (ref.watch(canEditMemberLinkProvider(key)))
          AppButton(
            label: member.personId == null
                ? 'Vincular persona'
                : 'Cambiar vinculación',
            leadingIcon: Icons.link_rounded,
            variant: AppButtonVariant.ghost,
            onPressed: () => AppBottomSheet.show<void>(
              context,
              title: 'La cuenta y su persona',
              builder: (_) => _MemberLinkEditor(member: member),
            ),
          ),
      ],
    );
  }
}

class _MemberLinkEditor extends ConsumerStatefulWidget {
  const _MemberLinkEditor({required this.member});
  final GroupMember member;
  @override
  ConsumerState<_MemberLinkEditor> createState() => _MemberLinkEditorState();
}

class _MemberLinkEditorState extends ConsumerState<_MemberLinkEditor> {
  late String _selected = widget.member.personId ?? '';
  Future<void> _save(Person? next) async {
    final member = widget.member;
    final controller = ref.read(
      memberLinkControllerProvider(member.groupId).notifier,
    );
    final demotes = controller.losesAdmin(member, next);
    final confirmed = await AppDialog.show(
      context,
      title: '¿Cambiar la vinculación?',
      description:
          'Los movimientos seguirán perteneciendo a sus personas originales. No se trasladan ni se cambian sus fotos.${demotes ? ' Esta cuenta dejará de ser administradora.' : ''}${next?.isActive == false ? ' La persona elegida está inactiva; no se reactivará al vincularla.' : ''}',
      confirmLabel: 'Confirmar vinculación',
    );
    if (!confirmed || !mounted) return;
    final saved = await controller.change(member, next);
    if (saved && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member, id = member.groupId;
    final action = ref.watch(memberLinkControllerProvider(id));
    return ref
        .watch(personsProvider(id))
        .when(
          loading: () => const LoadingIndicator(label: 'Consultando personas…'),
          error: (error, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'Personas no disponibles',
            description: failureMessage(error),
            actionLabel: 'Reintentar',
            onAction: () => ref.invalidate(personsProvider(id)),
          ),
          data: (_) {
            final candidates = ref.watch(
              memberLinkCandidatesProvider((id, member)),
            );
            final options = {
              '': 'Sin persona vinculada',
              for (final p in candidates)
                p.id: '${p.displayName}${p.isActive ? '' : ' (inactiva)'}',
            };
            Person? next;
            for (final p in candidates) {
              if (p.id == _selected) next = p;
            }
            final valid = options.containsKey(_selected);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  member.displayName,
                  style: AppTypography.of(context).editorialTitle,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Una persona solo puede estar vinculada a una cuenta del grupo. Los vínculos de cuentas que salieron siguen reservados.',
                  style: AppTypography.of(context).bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppDropdown<String>(
                  label: 'Persona interna',
                  value: valid ? _selected : '',
                  options: options,
                  onChanged: action.isLoading
                      ? null
                      : (value) {
                          if (value != null) setState(() => _selected = value);
                        },
                ),
                if (next?.isActive == false)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      'Persona inactiva: conserva el historial, pero no permite ser administrador.',
                      style: AppTypography.of(context).bodyMedium,
                    ),
                  ),
                if (action.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(failureMessage(action.error!)),
                  ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Guardar vinculación',
                  leadingIcon: Icons.link_rounded,
                  loading: action.isLoading,
                  onPressed: valid && _selected != (member.personId ?? '')
                      ? () => _save(next)
                      : null,
                ),
              ],
            );
          },
        );
  }
}
