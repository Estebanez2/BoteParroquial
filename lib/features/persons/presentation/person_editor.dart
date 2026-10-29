import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/person.dart';
import '../../../models/year_month.dart';
import '../../../models/photo_target.dart';
import '../../photos/presentation/photo_view.dart';
import '../providers/person_providers.dart';

Future<void> showPersonEditor(
  BuildContext context,
  WidgetRef ref,
  String groupId, {
  Person? person,
}) async {
  ref.read(personControllerProvider(groupId).notifier).clearError();
  await Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      transitionDuration: AppMotion.duration(context, AppMotion.durationNormal),
      reverseTransitionDuration: AppMotion.duration(
        context,
        AppMotion.durationNormal,
      ),
      pageBuilder: (context, animation, secondaryAnimation) => AppScaffold(
        maxWidth: AppSpacing.readingMax,
        appBar: AppTopBar(
          title: person == null ? 'Nueva persona' : 'Editar persona',
          leading: Consumer(
            builder: (context, ref, _) => AppIconButton(
              icon: Icons.arrow_back_rounded,
              label: 'Volver a personas',
              onPressed: ref.watch(personControllerProvider(groupId)).isLoading
                  ? null
                  : () => Navigator.pop(context),
            ),
          ),
        ),
        child: PersonEditor(groupId: groupId, person: person),
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
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
  String? _draftId;
  YearMonth? _firstMonth;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.person?.displayName);
    _notes = TextEditingController(text: widget.person?.notes);
    if (widget.person == null) {
      _draftId = ref
          .read(personControllerProvider(widget.groupId).notifier)
          .startCreate();
    }
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
                  AppHeroPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.person == null
                              ? 'Añade una persona'
                              : 'Los detalles importan',
                          style: AppTypography.of(context).editorialTitle,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Incluye a las personas de tu comunidad, tengan o no una cuenta en la aplicación.',
                          style: AppTypography.of(context).bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _name,
                      builder: (context, value, child) => widget.person == null
                          ? AppAvatar(
                              name: value.text,
                              size: AppAvatarSize.editor,
                            )
                          : PhotoAvatar(
                              target: PhotoTarget.person(
                                groupId,
                                widget.person!.id,
                              ),
                              name: value.text,
                              size: AppAvatarSize.editor,
                              interactive: true,
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.person == null
                        ? 'Guarda la persona para poder añadir su foto. Mientras tanto, usaremos sus iniciales.'
                        : 'Toca la imagen para consultar o cambiar su foto.',
                    textAlign: TextAlign.center,
                    style: AppTypography.of(context).bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppCard(
                    child: AppTextField(
                      label: 'Nombre',
                      controller: _name,
                      validator: controller.validateName,
                      enabled: !action.isLoading,
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    child: AppTextField(
                      label: 'Notas (opcional)',
                      controller: _notes,
                      validator: controller.validateNotes,
                      enabled: !action.isLoading,
                      helper:
                          'Las notas son visibles para los miembros del grupo.',
                      minLines: 3,
                      maxLines: 5,
                      icon: Icons.notes_outlined,
                    ),
                  ),
                  if (widget.person == null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    AppReveal(
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Su primer mes de cuota',
                              style: AppTypography.of(context).headingSmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Opcional. Elige desde qué mes participa; no se deduce de la fecha de alta. Si lo dejas pendiente, podrás elegirlo en su ficha.',
                              style: AppTypography.of(context).bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppChoiceBar<bool>(
                              options: const {
                                false: 'Más adelante',
                                true: 'Elegir ahora',
                              },
                              value: _firstMonth != null,
                              enabled: !action.isLoading,
                              onChanged: (enabled) => setState(
                                () => _firstMonth = enabled
                                    ? controller.currentMonth()
                                    : null,
                              ),
                            ),
                            if (_firstMonth != null) ...[
                              const SizedBox(height: AppSpacing.lg),
                              AppMonthField(
                                label: 'Primer mes incluido',
                                value: _firstMonth!.firstDayUtc,
                                lastYear: controller.currentMonth().year,
                                enabled: !action.isLoading,
                                onChanged: (date) => setState(
                                  () => _firstMonth = YearMonth.fromDate(date),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
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
                    leadingIcon: Icons.save_outlined,
                    fullWidth: true,
                    loading: action.isLoading,
                    onPressed: action.isLoading
                        ? null
                        : () async {
                            if (!(_formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            if (_firstMonth != null) {
                              final error = controller.validateFirstMonth(
                                _firstMonth,
                              );
                              if (error != null) {
                                AppSnackbar.show(
                                  context,
                                  error,
                                  variant: AppSnackbarVariant.error,
                                );
                                return;
                              }
                              final confirmed = await AppDialog.show(
                                context,
                                title: 'Confirmar su primer mes',
                                description:
                                    '${_name.text.trim()} participará desde $_firstMonth, incluido. Sus obligaciones se calcularán con las cuotas del grupo; no se marca ningún mes como pagado.',
                                confirmLabel: 'Crear persona y periodo',
                              );
                              if (!context.mounted || !confirmed) return;
                            }
                            final saved = await controller.save(
                              person: widget.person,
                              name: _name.text,
                              notes: _notes.text,
                              id: _draftId,
                              firstMonth: _firstMonth,
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
