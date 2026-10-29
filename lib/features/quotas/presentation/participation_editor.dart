import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/person.dart';
import '../../../models/year_month.dart';
import '../../persons/providers/person_providers.dart';
import '../providers/quota_providers.dart';

Future<void> showParticipationEditor(
  BuildContext context,
  WidgetRef ref,
  Person person, {
  required bool starting,
}) async {
  ref.read(quotaControllerProvider(person.groupId).notifier).clearError();
  await AppBottomSheet.show<void>(
    context,
    title: starting
        ? (person.isActive ? 'Su primer mes' : 'Volver a participar')
        : 'Cerrar esta etapa',
    builder: (_) => _ParticipationEditor(person: person, starting: starting),
  );
}

class _ParticipationEditor extends ConsumerStatefulWidget {
  const _ParticipationEditor({required this.person, required this.starting});
  final Person person;
  final bool starting;
  @override
  ConsumerState<_ParticipationEditor> createState() =>
      _ParticipationEditorState();
}

class _ParticipationEditorState extends ConsumerState<_ParticipationEditor> {
  late YearMonth _month;
  @override
  void initState() {
    super.initState();
    _month = ref.read(quotaMonthProvider(widget.person.groupId));
  }

  Future<void> _save() async {
    final person = widget.person;
    final confirmed = await AppDialog.show(
      context,
      title: widget.starting
          ? '¿Abrir su periodo?'
          : '¿Cerrar su periodo e inactivar?',
      description: widget.starting
          ? '${person.displayName} computará desde $_month. Si estaba inactiva se reactivará; no recuperará permisos anteriores de administrador. No se trasladan movimientos ni se asignan pagos.'
          : '${person.displayName} computará hasta $_month, incluido. Conservará su historial. Si tiene un administrador vinculado, pasará a miembro.',
      confirmLabel: widget.starting ? 'Confirmar primer mes' : 'Confirmar baja',
    );
    if (!confirmed || !mounted) return;
    final saved = await ref
        .read(quotaControllerProvider(person.groupId).notifier)
        .participation(person, _month, widget.starting);
    if (saved && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.person,
        action = ref.watch(quotaControllerProvider(widget.person.groupId));
    if (!ref.watch(canManagePersonsProvider(person.groupId))) {
      return const Text('Ya no tienes permiso para gestionar esta persona.');
    }
    return ref
        .watch(participationPeriodsProvider((person.groupId, person.id)))
        .when(
          skipLoadingOnReload: false,
          skipLoadingOnRefresh: false,
          loading: () => const LoadingIndicator(label: 'Consultando periodos…'),
          error: (e, _) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Periodos no disponibles',
            description: failureMessage(e),
            actionLabel: 'Reintentar',
            onAction: () => ref.invalidate(
              participationPeriodsProvider((person.groupId, person.id)),
            ),
          ),
          data: (_) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                person.displayName,
                style: AppTypography.of(context).editorialTitle,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.starting
                    ? 'Elige el primer mes computable, hasta el mes actual. Puede coincidir con el último mes de la etapa anterior: ese mes contará una sola vez.'
                    : 'Elige el último mes que debe computar. Ese mes queda incluido; los meses posteriores no generarán nuevas cuotas.',
                style: AppTypography.of(context).bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppMonthField(
                label: widget.starting ? 'Primer mes' : 'Último mes incluido',
                value: _month.firstDayUtc,
                enabled: !action.isLoading,
                lastYear: ref.watch(quotaMonthProvider(person.groupId)).year,
                onChanged: (date) =>
                    setState(() => _month = YearMonth.fromDate(date)),
              ),
              if (action.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(failureMessage(action.error!)),
                ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: widget.starting ? 'Revisar primer mes' : 'Revisar baja',
                leadingIcon: Icons.calendar_month_outlined,
                loading: action.isLoading,
                onPressed: _save,
              ),
            ],
          ),
        );
  }
}
