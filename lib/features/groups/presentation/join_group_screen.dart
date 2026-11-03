import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/group_invitation.dart';
import '../providers/group_invitation_providers.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key, this.initialCode});
  final String? initialCode;
  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _code = TextEditingController();
  @override
  void initState() {
    super.initState();
    _prepareLink();
  }

  @override
  void didUpdateWidget(covariant JoinGroupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCode != widget.initialCode) _prepareLink();
  }

  void _prepareLink() {
    final code = widget.initialCode;
    if (code == null) return;
    _code.text = code;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.initialCode == code) {
        ref.read(joinGroupProvider.notifier).preview(code);
      }
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(joinGroupProvider),
        controller = ref.read(joinGroupProvider.notifier);
    return AppScaffold(
      maxWidth: AppSpacing.readingMax,
      appBar: AppTopBar(
        title: 'Entrar en un grupo',
        leading: AppIconButton(
          icon: Icons.arrow_back_rounded,
          label: 'Volver a mis grupos',
          onPressed: () => context.go('/'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppReveal(
            child: Text(
              'Hay un sitio\npara ti.',
              style: AppTypography.of(context).displayLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Pega el código o enlace que han compartido contigo. Antes de entrar verás a qué espacio corresponde.',
            style: AppTypography.of(context).bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'Código o enlace de invitación',
            controller: _code,
            enabled: !state.loading,
            onChanged: (_) => controller.clear(),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Ver invitación',
            validate: () => controller.validateCode(_code.text),
            leadingIcon: Icons.search_rounded,
            loading: state.loading,
            onPressed: () => controller.preview(_code.text),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: Text(failureMessage(state.error!)),
            ),
          if (state.preview != null) ...[
            const SizedBox(height: AppSpacing.xl),
            AppGroupEntry(
              onOpen: (origin) => context.go(
                '/groups/${state.preview!.code.groupId}',
                extra: origin,
              ),
              builder: (_, activate) => AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      state.preview!.groupName,
                      style: AppTypography.of(context).editorialTitle,
                    ),
                    AppBadge(state.preview!.currency),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.preview!.isReadmission
                          ? 'Tu vuelta necesita aprobación. Volverás como miembro, conservando tu vinculación e historial anteriores.'
                          : 'Entrarás como miembro con acceso a la información económica. La persona interna se vincula por separado.',
                      style: AppTypography.of(context).bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (state.result == JoinRequestStatus.pending)
                      const EmptyState(
                        icon: Icons.hourglass_top_rounded,
                        title: 'Tu solicitud está enviada',
                        description:
                            'Un administrador tiene que aprobarla. Puedes volver a comprobar este código más adelante.',
                      )
                    else if (state.result == JoinRequestStatus.approved)
                      AppButton(
                        label: 'Abrir grupo',
                        tapEffect: AppTapEffect.none,
                        onPressed: activate,
                      )
                    else
                      AppButton(
                        label: state.preview!.requiresApproval
                            ? 'Solicitar entrada'
                            : 'Entrar como miembro',
                        loading: state.loading,
                        onPressed: () => controller.submit(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
