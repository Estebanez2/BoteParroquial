import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../providers/group_deletion_providers.dart';

class GroupDeletionScreen extends ConsumerStatefulWidget {
  const GroupDeletionScreen({
    super.key,
    required this.groupId,
    this.pendingName,
  });
  final String groupId;
  final String? pendingName;
  @override
  ConsumerState<GroupDeletionScreen> createState() =>
      _GroupDeletionScreenState();
}

class _GroupDeletionScreenState extends ConsumerState<GroupDeletionScreen> {
  final _name = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = AppTypography.of(context),
        action = ref.watch(groupDeletionControllerProvider(widget.groupId));
    Widget form(String name) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text('Eliminar $name', style: type.editorialTitle),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Se borrarán definitivamente personas, miembros, fotos, cuotas, movimientos y auditoría de este grupo. Los demás grupos y cuentas se conservan. Exporta antes lo que quieras guardar.',
          style: type.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (widget.pendingName == null)
          AppButton(
            label: 'Abrir informes y exportar',
            variant: AppButtonVariant.outline,
            leadingIcon: Icons.ios_share,
            onPressed: action.isLoading
                ? null
                : () => context.push('/groups/${widget.groupId}/reports'),
          ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Escribe el nombre exacto: $name',
          controller: _name,
          enabled: !action.isLoading,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'La primera confirmación bloquea el grupo de forma irreversible. Se deja un margen de tres minutos para que terminen envíos y avisos en curso; después se reanuda desde Inicio. Si se interrumpe, el bloqueo y el progreso se conservan.',
          style: type.bodySmall,
        ),
        if (action.hasError)
          Text(failureMessage(action.error!), style: type.bodyMedium),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Verificar Google y eliminar',
          leadingIcon: Icons.delete_forever_outlined,
          loading: action.isLoading,
          onPressed: () async {
            final accepted = await AppDialog.show(
              context,
              title: '¿Eliminar definitivamente $name?',
              description:
                  'No podrás recuperar el grupo desde la app. Esta acción afecta a todos sus miembros.',
              confirmLabel: 'Verificar y continuar',
            );
            if (!accepted || !mounted) return;
            final result = await ref
                .read(groupDeletionControllerProvider(widget.groupId).notifier)
                .remove(name, _name.text);
            if (!context.mounted || result == null) return;
            context.go('/');
            AppSnackbar.show(
              context,
              result
                  ? 'Grupo eliminado.'
                  : 'Grupo bloqueado para su eliminación. Tras tres minutos, reanuda desde Inicio.',
              variant: AppSnackbarVariant.success,
            );
          },
        ),
      ],
    );
    return AppScaffold(
      maxWidth: AppSpacing.readingMax,
      appBar: AppTopBar(
        title: 'Eliminar grupo',
        leading: AppIconButton(
          icon: Icons.arrow_back_rounded,
          label: 'Volver a Inicio',
          onPressed: () => context.go('/'),
        ),
      ),
      child: widget.pendingName != null
          ? form(widget.pendingName!)
          : ref
                .watch(groupDeletionPreviewProvider(widget.groupId))
                .when(
                  loading: () => const LoadingIndicator(
                    label: 'Comprobando el grupo en el servidor…',
                  ),
                  error: (e, _) => EmptyState(
                    icon: Icons.lock_outline,
                    title: 'No se puede preparar la eliminación',
                    description: failureMessage(e),
                  ),
                  data: (preview) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BalanceCard(
                        balanceCents: preview.balanceCents,
                        currency: preview.currency,
                        caption: 'Saldo actual · eliminación irreversible',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        '${preview.persons} personas · ${preview.members} membresías · ${preview.movements} movimientos',
                        style: type.bodyMedium,
                      ),
                      form(preview.name),
                    ],
                  ),
                ),
    );
  }
}
