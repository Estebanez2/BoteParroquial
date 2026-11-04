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
import '../../../models/photo_target.dart';

class GroupEditorScreen extends ConsumerStatefulWidget {
  const GroupEditorScreen({super.key, this.groupId});
  final String? groupId;
  @override
  ConsumerState<GroupEditorScreen> createState() => _GroupEditorScreenState();
}

class _GroupEditorScreenState extends ConsumerState<GroupEditorScreen> {
  final _guard = GlobalKey<AppFormGuardState>();
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
        onPressed: () => _guard.currentState == null
            ? context.go(widget.groupId == null ? '/' : '/groups/$_id')
            : _guard.currentState!.requestExit(
                () => context.go(widget.groupId == null ? '/' : '/groups/$_id'),
              ),
      ),
    ),
    child: widget.groupId == null
        ? _GroupForm(key: ValueKey(_id), id: _id, guard: _guard)
        : GroupAccessBody(
            groupId: _id,
            showIdentity: false,
            builder: (group, _) => ref.watch(canEditGroupProvider(_id))
                ? _GroupForm(
                    key: ValueKey(_id),
                    id: _id,
                    original: group,
                    guard: _guard,
                  )
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
  const _GroupForm({
    super.key,
    required this.id,
    this.original,
    required this.guard,
  });
  final GlobalKey<AppFormGuardState> guard;
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
    widget.guard.currentState?.saved();
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
    ref.listen(groupDraftPhotoProvider(widget.id), (previous, next) {
      if (!next.busy && next.draft != null && next.draft != previous?.draft) {
        AppSoundScope.emit(context, UiSound.photo);
      }
      if (next.error != null && next.error != previous?.error) {
        AppSoundScope.emit(context, UiSound.warning);
      }
    });
    final photo = ref.watch(groupDraftPhotoProvider(widget.id));
    final locked = action.isLoading || photo.busy;
    final fieldsLocked = locked || controller.groupCreated;
    return AppFormGuard(
      key: widget.guard,
      busy: locked,
      changes: Listenable.merge([_name, _description]),
      isDirty: () =>
          _name.text != (_original?.name ?? '') ||
          _description.text != (_original?.description ?? '') ||
          (_original == null &&
              (_currency != 'EUR' ||
                  _timeZone != 'Europe/Madrid' ||
                  !_createPerson)) ||
          photo.draft != null,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_original == null) ...[
              if (photo.draft != null)
                AppCover(
                  name: _name.text,
                  panoramic: true,
                  image: photo.draft == null ? null : MemoryImage(photo.draft!),
                  loading: photo.busy,
                ),
              Text(
                'Foto del grupo · opcional',
                style: AppTypography.of(context).labelSmall,
              ),
              AppAdaptiveRow(
                children: [
                  AppButton(
                    label: 'Galería',
                    leadingIcon: Icons.photo_library_outlined,
                    onPressed: locked
                        ? null
                        : () => ref
                              .read(groupDraftPhotoProvider(widget.id).notifier)
                              .select(
                                PhotoSource.gallery,
                                darkTheme:
                                    Theme.of(context).brightness ==
                                    Brightness.dark,
                              ),
                  ),
                  AppButton(
                    label: 'Cámara',
                    leadingIcon: Icons.camera_alt_outlined,
                    variant: AppButtonVariant.outline,
                    onPressed: locked
                        ? null
                        : () => ref
                              .read(groupDraftPhotoProvider(widget.id).notifier)
                              .select(
                                PhotoSource.camera,
                                darkTheme:
                                    Theme.of(context).brightness ==
                                    Brightness.dark,
                              ),
                  ),
                ],
              ),
              if (photo.draft != null)
                AppAdaptiveRow(
                  children: [
                    AppButton(
                      label: 'Editar foto',
                      leadingIcon: Icons.crop_rotate_outlined,
                      variant: AppButtonVariant.ghost,
                      onPressed: locked
                          ? null
                          : () => ref
                                .read(
                                  groupDraftPhotoProvider(widget.id).notifier,
                                )
                                .edit(
                                  darkTheme:
                                      Theme.of(context).brightness ==
                                      Brightness.dark,
                                ),
                    ),
                    AppButton(
                      label: 'Quitar foto',
                      leadingIcon: Icons.close_rounded,
                      variant: AppButtonVariant.ghost,
                      onPressed: locked
                          ? null
                          : ref
                                .read(
                                  groupDraftPhotoProvider(widget.id).notifier,
                                )
                                .clear,
                    ),
                  ],
                ),
              if (photo.error != null)
                Text(photo.error!, style: AppTypography.of(context).bodySmall),
              const SizedBox(height: AppSpacing.lg),
            ],
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Nombre del grupo',
                    controller: _name,
                    validator: controller.validateName,
                    enabled: !fieldsLocked,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'Descripción · opcional',
                    controller: _description,
                    maxLines: 3,
                    validator: controller.validateDescription,
                    enabled: !fieldsLocked,
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
                      enabled: !fieldsLocked,
                      onChanged: (value) {
                        if (value != null) setState(() => _currency = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppDropdown<String>(
                      label: 'Calendario del grupo',
                      value: _timeZone,
                      options: ref.watch(groupTimeZonesProvider),
                      enabled: !fieldsLocked,
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
                      enabled: !fieldsLocked,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _createPerson = value);
                        }
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
              label: _original == null
                  ? controller.groupCreated
                        ? photo.draft == null
                              ? 'Abrir mi grupo'
                              : 'Reintentar guardar foto'
                        : 'Crear mi grupo'
                  : 'Guardar grupo',
              validate: () => _form.currentState?.validate() ?? false,
              leadingIcon: Icons.check_rounded,
              fullWidth: true,
              loading: locked,
              onPressed: locked ? null : _save,
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
      ),
    );
  }
}
