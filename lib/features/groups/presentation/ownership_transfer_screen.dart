import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/group_member.dart';
import '../../persons/providers/person_providers.dart';
import '../providers/group_providers.dart';
import '../providers/member_role_providers.dart';
import 'group_access_body.dart';

class OwnershipTransferScreen extends ConsumerStatefulWidget {
  const OwnershipTransferScreen({super.key, required this.groupId});
  final String groupId;
  @override
  ConsumerState<OwnershipTransferScreen> createState() =>
      _OwnershipTransferState();
}

class _OwnershipTransferState extends ConsumerState<OwnershipTransferScreen> {
  final _form = GlobalKey<FormState>();
  final _confirmation = TextEditingController();
  String? _selected;
  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.groupId;
    final action = ref.watch(memberRoleControllerProvider(id));
    return AppScaffold(
      maxWidth: AppSpacing.readingMax,
      appBar: AppTopBar(
        title: 'Entregar el control',
        leading: AppIconButton(
          icon: Icons.arrow_back_rounded,
          label: 'Volver a miembros',
          onPressed: action.isLoading
              ? null
              : () => context.go('/groups/$id/members'),
        ),
      ),
      child: GroupAccessBody(
        groupId: id,
        builder: (group, membership) {
          if (!ref.watch(canTransferOwnershipProvider(id))) {
            return const EmptyState(
              icon: Icons.lock_outline,
              title: 'Solo el propietario puede transferir',
              description:
                  'Consulta Miembros para ver quién tiene ahora el control del grupo.',
            );
          }
          final persons = ref.watch(personsProvider(id));
          final members = ref.watch(groupMembersProvider(id));
          if (persons.hasError || members.hasError) {
            return EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'No pudimos comprobar los miembros',
              description: failureMessage(persons.error ?? members.error!),
              actionLabel: 'Reintentar',
              onAction: () {
                ref.invalidate(personsProvider(id));
                ref.invalidate(groupMembersProvider(id));
              },
            );
          }
          if (persons.isLoading || members.isLoading) {
            return const LoadingIndicator(label: 'Comprobando vínculos…');
          }
          final candidates = ref.watch(ownershipCandidatesProvider(id));
          if (candidates.isEmpty) {
            return const EmptyState(
              icon: Icons.person_add_alt_outlined,
              title: 'Prepara a quien tomará el relevo',
              description:
                  'Necesitas otro miembro activo con una persona activa vinculada. Puedes hacerlo desde Miembros.',
            );
          }
          GroupMember? target;
          for (final candidate in candidates) {
            if (candidate.uid == _selected) target = candidate;
          }
          final chosen = target;
          return Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppReveal(
                  child: AppHeroPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppBadge(
                          'UN NUEVO RESPONSABLE',
                          icon: Icons.workspace_premium_outlined,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'El siguiente capítulo de ${group.name}',
                          style: AppTypography.of(context).editorialTitle,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'La persona elegida tendrá el control completo. Tú pasarás a miembro y conservarás tu vínculo e historial. Solo el nuevo propietario podrá devolverte la propiedad.',
                          style: AppTypography.of(context).bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppDropdown<String>(
                        label: 'Nuevo propietario',
                        value: chosen?.uid,
                        options: {
                          for (final m in candidates) m.uid: m.displayName,
                        },
                        onChanged: action.isLoading
                            ? null
                            : (value) => setState(() => _selected = value),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppTextField(
                        label: 'Escribe el nombre del grupo',
                        helper: group.name,
                        controller: _confirmation,
                        enabled: !action.isLoading,
                        validator: (value) => ref
                            .read(memberRoleControllerProvider(id).notifier)
                            .validateConfirmation(group.name, value),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'A continuación verificaremos tu cuenta con Google. Elige tu misma cuenta para confirmar.',
                        style: AppTypography.of(context).bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (action.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Text(
                      failureMessage(action.error!),
                      style: AppTypography.of(context).bodyMedium,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Verificar Google y transferir',
                  leadingIcon: Icons.verified_user_outlined,
                  loading: action.isLoading,
                  onPressed: chosen == null
                      ? null
                      : () async {
                          if (!_form.currentState!.validate()) return;
                          final router = GoRouter.of(context);
                          final saved = await ref
                              .read(memberRoleControllerProvider(id).notifier)
                              .transfer(group, chosen, _confirmation.text);
                          if (saved && mounted) {
                            router.go('/groups/$id/members');
                          }
                        },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
