import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/person.dart';
import '../providers/person_providers.dart';

Future<void> showPersonEditor(
  BuildContext context,
  WidgetRef ref,
  String groupId, {
  Person? person,
}) async {
  ref.read(personControllerProvider(groupId).notifier).clearError();
  await AppBottomSheet.show<void>(
    context,
    title: person == null
        ? 'Una persona más, un bote más nuestro.'
        : 'Cuidemos los detalles.',
    isDismissible: false,
    enableDrag: false,
    builder: (context) => PersonEditor(groupId: groupId, person: person),
  );
}

class PersonEditor extends ConsumerStatefulWidget {
  const PersonEditor({super.key, required this.groupId, this.person});
  final String groupId;
  final Person? person;
  @override
  ConsumerState<PersonEditor> createState() => _PersonEditorState();
}

class _PersonEditorState extends ConsumerState<PersonEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _notes;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.person?.displayName);
    _notes = TextEditingController(text: widget.person?.notes);
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupId = widget.groupId;
    final action = ref.watch(personControllerProvider(groupId));
    final controller = ref.read(personControllerProvider(groupId).notifier);
    final allowed = ref.watch(canManagePersonsProvider(groupId));
    return PopScope(
      canPop: !action.isLoading,
      child: !allowed
          ? Column(
              children: [
                const EmptyState(
                  icon: Icons.lock_outline,
                  title: 'Acceso no disponible',
                  description:
                      'Ya no puedes gestionar las personas de este grupo.',
                ),
                AppButton(
                  label: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'No necesita una cuenta de Google para formar parte del bote.',
                    style: AppTypography.of(context).bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: 'Nombre',
                    controller: _name,
                    validator: controller.validateName,
                    enabled: !action.isLoading,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'Notas (opcional)',
                    controller: _notes,
                    validator: controller.validateNotes,
                    enabled: !action.isLoading,
                    helper:
                        'Las notas son visibles para los miembros del grupo.',
                  ),
                  if (action.hasError) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      failureMessage(action.error!),
                      style: AppTypography.of(context).bodyMedium.copyWith(
                        color: AppColors.of(context).danger,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Guardar persona',
                    loading: action.isLoading,
                    onPressed: action.isLoading
                        ? null
                        : () async {
                            if (!(_formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            final saved = await controller.save(
                              person: widget.person,
                              name: _name.text,
                              notes: _notes.text,
                            );
                            if (!context.mounted || !saved) return;
                            // Allow the pop after the controller has left its loading state.
                            await WidgetsBinding.instance.endOfFrame;
                            if (context.mounted) Navigator.pop(context);
                          },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Cancelar',
                    variant: AppButtonVariant.ghost,
                    onPressed: action.isLoading
                        ? null
                        : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
    );
  }
}
