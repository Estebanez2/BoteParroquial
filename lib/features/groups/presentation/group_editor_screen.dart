import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/group_deletion_providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/group.dart';
import '../../../models/group_input.dart';
import '../providers/group_management_providers.dart';
import 'group_access_body.dart';
import 'group_widgets.dart';

class GroupEditorScreen extends ConsumerStatefulWidget {
  const GroupEditorScreen({super.key, this.groupId});
  final String? groupId;
  @override
  ConsumerState<GroupEditorScreen> createState() => _GroupEditorScreenState();
}

class _GroupEditorScreenState extends ConsumerState<GroupEditorScreen> {
  late final String _id;
  @override
  void initState() {
    super.initState();
    _id = widget.groupId ?? ref.read(groupManagementRepositoryProvider).newId();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    maxWidth: AppSpacing.readingMax,
    appBar: AppTopBar(
      title: widget.groupId == null ? 'Nuevo grupo' : 'Tu grupo',
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver',
        onPressed: () =>
            context.go(widget.groupId == null ? '/' : '/groups/$_id'),
      ),
    ),
    child: widget.groupId == null
        ? _GroupForm(key: ValueKey(_id), id: _id)
        : GroupAccessBody(
            groupId: _id,
            builder: (group, _) => ref.watch(canEditGroupProvider(_id))
                ? _GroupForm(key: ValueKey(_id), id: _id, original: group)
                : const EmptyState(
                    icon: Icons.lock_outline,
                    title: 'Solo gestión autorizada',
                    description:
                        'Necesitas ser propietario o administrador autorizado para editar el grupo.',
                  ),
          ),
  );
}

class _GroupForm extends ConsumerStatefulWidget {
  const _GroupForm({super.key, required this.id, this.original});
  final String id;
  final Group? original;
  @override
  ConsumerState<_GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends ConsumerState<_GroupForm> {
  final _form = GlobalKey<FormState>();
  late final Group? _original = widget.original;
  late final _name = TextEditingController(text: _original?.name ?? '');
  late final _description = TextEditingController(
    text: _original?.description ?? '',
  );
  String _currency = 'EUR', _timeZone = 'Europe/Madrid';
  bool _createPerson = true;
  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final saved = await ref
        .read(groupManagementControllerProvider(widget.id).notifier)
        .save(
          name: _name.text,
          description: _description.text,
          original: _original,
          creation: _original != null
              ? null
              : GroupInput(
                  name: _name.text,
                  description: _description.text,
                  currency: _currency,
                  timeZone: _timeZone,
                  createOwnerPerson: _createPerson,
                ),
        );
    if (!mounted || !saved) return;
    context.go('/groups/${widget.id}');
    AppSnackbar.show(
      context,
      _original == null ? 'Tu nuevo grupo está listo.' : 'Grupo actualizado.',
      variant: AppSnackbarVariant.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = groupManagementControllerProvider(widget.id);
    final action = ref.watch(provider),
        controller = ref.read(provider.notifier);
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GroupOpening(
            eyebrow: _original == null
                ? 'UN NUEVO COMIENZO'
                : 'LA IDENTIDAD DE TU ESPACIO',
            title: _original == null
                ? 'Dale un lugar\na lo que compartís.'
                : 'Un grupo con\nnombre propio.',
            description: _original == null
                ? 'Crea un fondo independiente. Tú serás su propietario y decidirás quién forma parte.'
                : 'Ajusta el nombre y la descripción conservando su historia.',
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Nombre del grupo',
                  controller: _name,
                  validator: controller.validateName,
                  enabled: !action.isLoading,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Descripción · opcional',
                  controller: _description,
                  maxLines: 3,
                  validator: controller.validateDescription,
                  enabled: !action.isLoading,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_original == null)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppDropdown<String>(
                    label: 'Moneda · no podrá cambiarse',
                    value: _currency,
                    options: ref.watch(groupCurrenciesProvider),
                    enabled: !action.isLoading,
                    onChanged: (value) {
                      if (value != null) setState(() => _currency = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppDropdown<String>(
                    label: 'Calendario del grupo',
                    value: _timeZone,
                    options: ref.watch(groupTimeZonesProvider),
                    enabled: !action.isLoading,
                    onChanged: (value) {
                      if (value != null) setState(() => _timeZone = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppDropdown<bool>(
                    label: 'Tu persona interna',
                    hint: 'Elige cómo quieres comenzar',
                    value: _createPerson,
                    options: const {
                      true: 'Crear una persona vinculada a mí',
                      false: 'Empezar sin mi persona interna',
                    },
                    enabled: !action.isLoading,
                    onChanged: (value) {
                      if (value != null) setState(() => _createPerson = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'La persona interna permite asociarte aportaciones. Es distinta de tu cuenta y conserva su propio historial.',
                    style: AppTypography.of(context).bodySmall,
                  ),
                ],
              ),
            )
          else
            AppCard(
              child: Text(
                'Moneda: ${_original.currency} · Zona: ${_original.timeZone}',
                style: AppTypography.of(context).bodyMedium,
              ),
            ),
          if (action.hasError)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: Text(failureMessage(action.error!)),
            ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: _original == null ? 'Crear mi grupo' : 'Guardar grupo',
            leadingIcon: Icons.check_rounded,
            fullWidth: true,
            loading: action.isLoading,
            onPressed: _save,
          ),
          if (_original != null &&
              ref.watch(canDeleteGroupProvider(widget.id))) ...[
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Eliminar grupo definitivamente',
              leadingIcon: Icons.delete_forever_outlined,
              variant: AppButtonVariant.ghost,
              onPressed: () => context.push('/groups/${widget.id}/delete'),
            ),
          ],
        ],
      ),
    );
  }
}
