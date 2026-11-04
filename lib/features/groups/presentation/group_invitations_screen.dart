import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/group_invitation.dart';
import '../providers/group_invitation_providers.dart';
import '../providers/group_management_providers.dart';
import 'group_access_body.dart';

class GroupInvitationsScreen extends ConsumerWidget {
  const GroupInvitationsScreen({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    maxWidth: AppSpacing.readingMax,
    appBar: AppTopBar(
      title: 'Invitaciones',
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver al grupo',
        onPressed: () => context.go('/groups/$groupId'),
      ),
    ),
    child: GroupAccessBody(
      groupId: groupId,
      builder: (group, _) {
        final action = ref.watch(invitationControllerProvider(groupId));
        final manage = ref.watch(canEditGroupProvider(groupId));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppReveal(
              child: Text(
                'Un espacio para\ncompartir.',
                style: AppTypography.of(context).displayLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Comparte una invitación con la foto del grupo, su nombre y el enlace. Si no tiene foto, se enviará el logo de la app. También puedes copiar el enlace o el código.',
              style: AppTypography.of(context).bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            ref
                .watch(invitationSettingsProvider(groupId))
                .when(
                  skipLoadingOnRefresh: false,
                  skipLoadingOnReload: false,
                  loading: () =>
                      const LoadingIndicator(label: 'Preparando invitación…'),
                  error: (error, _) => EmptyState(
                    icon: Icons.error_outline,
                    title: 'Invitación no disponible',
                    description: failureMessage(error),
                    actionLabel: 'Reintentar',
                    onAction: () =>
                        ref.invalidate(invitationSettingsProvider(groupId)),
                  ),
                  data: (settings) => _InvitationCard(
                    groupId: groupId,
                    settings: settings,
                    canManage: manage,
                  ),
                ),
            if (action.hasError)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Text(failureMessage(action.error!)),
              ),
            if (manage) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Llaman a la puerta',
                style: AppTypography.of(context).editorialTitle,
              ),
              const SizedBox(height: AppSpacing.lg),
              ref
                  .watch(groupJoinRequestsProvider(groupId))
                  .when(
                    skipLoadingOnRefresh: false,
                    skipLoadingOnReload: false,
                    loading: () => const LoadingIndicator(
                      label: 'Consultando solicitudes…',
                    ),
                    error: (error, _) => EmptyState(
                      icon: Icons.error_outline,
                      title: 'Solicitudes no disponibles',
                      description: failureMessage(error),
                      actionLabel: 'Reintentar',
                      onAction: () =>
                          ref.invalidate(groupJoinRequestsProvider(groupId)),
                    ),
                    data: (requests) => requests.isEmpty
                        ? const EmptyState(
                            icon: Icons.mark_email_read_outlined,
                            title: 'Nadie está esperando',
                            description:
                                'Las solicitudes de entrada aparecerán aquí.',
                          )
                        : Column(
                            children: [
                              for (final request in requests)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.lg,
                                  ),
                                  child: AppCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          request.displayName,
                                          style: AppTypography.of(
                                            context,
                                          ).headingSmall,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        AppAdaptiveRow(
                                          children: [
                                            AppButton(
                                              label: 'Aceptar',
                                              leadingIcon: Icons.check_rounded,
                                              onPressed: action.isLoading
                                                  ? null
                                                  : () => _decide(
                                                      context,
                                                      ref,
                                                      request,
                                                      true,
                                                    ),
                                            ),
                                            AppButton(
                                              label: 'Rechazar',
                                              variant: AppButtonVariant.outline,
                                              onPressed: action.isLoading
                                                  ? null
                                                  : () => _decide(
                                                      context,
                                                      ref,
                                                      request,
                                                      false,
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
            ],
          ],
        );
      },
    ),
  );
  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    GroupJoinRequest request,
    bool approve,
  ) async {
    final confirmed = await AppDialog.show(
      context,
      title: approve
          ? '¿Aceptar a ${request.displayName}?'
          : '¿Rechazar esta solicitud?',
      description: approve
          ? 'Entrará como miembro y podrá consultar la información económica del grupo. No se le concede gestión ni se vincula una persona automáticamente.'
          : 'No se concederá acceso al grupo.',
      confirmLabel: approve ? 'Aceptar miembro' : 'Rechazar solicitud',
    );
    if (confirmed && context.mounted) {
      await ref
          .read(invitationControllerProvider(groupId).notifier)
          .decide(request, approve);
    }
  }
}

class _InvitationCard extends ConsumerWidget {
  const _InvitationCard({
    required this.groupId,
    required this.settings,
    required this.canManage,
  });
  final String groupId;
  final InvitationSettings? settings;
  final bool canManage;
  Future<void> _configure(BuildContext context, WidgetRef ref) async {
    final result = await AppBottomSheet.show<(bool, bool)>(
      context,
      title: 'Cómo entra la gente',
      builder: (context) => _SettingsForm(settings: settings),
    );
    if (result != null && context.mounted) {
      await ref
          .read(invitationControllerProvider(groupId).notifier)
          .configure(
            enabled: result.$1,
            requiresApproval: result.$2,
            original: settings,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(invitationControllerProvider(groupId)).isLoading;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBadge(
            settings?.enabled == true
                ? 'Invitación activa'
                : 'Invitación desactivada',
            tone: settings?.enabled == true ? AppTone.success : AppTone.neutral,
          ),
          const SizedBox(height: AppSpacing.md),
          if (settings?.enabled == true) ...[
            SelectableText(
              settings!.code.value,
              style: AppTypography.of(context).bodyLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              settings!.requiresApproval
                  ? 'Cada entrada requiere aprobación.'
                  : 'Las cuentas nuevas entran como miembros automáticamente. Quien ya estuvo en el grupo necesita aprobación para volver.',
              style: AppTypography.of(context).bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppAdaptiveRow(
              children: [
                AppButton(
                  label: 'Copiar código',
                  leadingIcon: Icons.copy_rounded,
                  onPressed: busy
                      ? null
                      : () async {
                          final copied = await ref
                              .read(
                                invitationControllerProvider(groupId).notifier,
                              )
                              .copy(settings!);
                          if (copied && context.mounted) {
                            AppSnackbar.show(
                              context,
                              'Código copiado.',
                              variant: AppSnackbarVariant.success,
                            );
                          }
                        },
                ),
                AppButton(
                  label: 'Compartir invitación',
                  variant: AppButtonVariant.outline,
                  leadingIcon: Icons.ios_share_rounded,
                  onPressed: busy
                      ? null
                      : () => ref
                            .read(
                              invitationControllerProvider(groupId).notifier,
                            )
                            .share(settings!),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Copiar enlace',
              variant: AppButtonVariant.ghost,
              leadingIcon: Icons.link_rounded,
              onPressed: busy
                  ? null
                  : () async {
                      final copied = await ref
                          .read(invitationControllerProvider(groupId).notifier)
                          .copyLink(settings!);
                      if (copied && context.mounted) {
                        AppSnackbar.show(
                          context,
                          'Enlace copiado.',
                          variant: AppSnackbarVariant.success,
                        );
                      }
                    },
            ),
          ] else
            Text(
              'Los códigos desactivados no permiten nuevas solicitudes ni entradas.',
              style: AppTypography.of(context).bodyMedium,
            ),
          if (canManage) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Configurar invitación',
              variant: AppButtonVariant.ghost,
              leadingIcon: Icons.tune_rounded,
              onPressed: busy ? null : () => _configure(context, ref),
            ),
            if (settings != null)
              AppButton(
                label: 'Regenerar código',
                variant: AppButtonVariant.ghost,
                leadingIcon: Icons.refresh_rounded,
                onPressed: busy
                    ? null
                    : () async {
                        final confirmed = await AppDialog.show(
                          context,
                          title: '¿Cambiar el código?',
                          description:
                              'El código anterior dejará de admitir entradas. Los miembros actuales y las solicitudes ya enviadas se conservan.',
                          confirmLabel: 'Regenerar código',
                        );
                        if (confirmed && context.mounted) {
                          await ref
                              .read(
                                invitationControllerProvider(groupId).notifier,
                              )
                              .configure(
                                enabled: settings!.enabled,
                                requiresApproval: settings!.requiresApproval,
                                original: settings,
                                regenerate: true,
                              );
                        }
                      },
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsForm extends StatefulWidget {
  const _SettingsForm({required this.settings});
  final InvitationSettings? settings;
  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  late bool _enabled = widget.settings?.enabled ?? false;
  late bool _approval = widget.settings?.requiresApproval ?? true;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppDropdown<bool>(
        label: 'Invitación',
        value: _enabled,
        options: const {false: 'Desactivada', true: 'Activada'},
        onChanged: (value) {
          if (value != null) setState(() => _enabled = value);
        },
      ),
      const SizedBox(height: AppSpacing.lg),
      AppDropdown<bool>(
        label: 'Cuentas nuevas',
        value: _approval,
        options: const {
          true: 'Con aprobación de un administrador',
          false: 'Entrada automática como miembro',
        },
        onChanged: (value) {
          if (value != null) setState(() => _approval = value);
        },
      ),
      const SizedBox(height: AppSpacing.xl),
      AppButton(
        label: 'Guardar invitación',
        onPressed: () => Navigator.pop(context, (_enabled, _approval)),
      ),
    ],
  );
}
