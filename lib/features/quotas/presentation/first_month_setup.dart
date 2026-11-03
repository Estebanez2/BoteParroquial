import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../models/year_month.dart';
import '../../persons/providers/person_providers.dart';
import '../providers/first_month_setup_providers.dart';
import '../providers/quota_providers.dart';

class FirstMonthSetupPanel extends ConsumerWidget {
  const FirstMonthSetupPanel({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(canManagePersonsProvider(groupId))) {
      return const SizedBox.shrink();
    }
    final pending = ref.watch(firstMonthCandidatesProvider(groupId));
    if (!pending.hasError &&
        !pending.isLoading &&
        pending.asData?.value.isEmpty == true) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppBadge(
              'PRIMER MES DE CUOTA',
              tone: AppTone.secondary,
              icon: Icons.event_available_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              pending.hasError
                  ? 'No pudimos comprobar los datos pendientes'
                  : pending.isLoading
                  ? 'Comprobando primeros meses…'
                  : '${pending.requireValue.length} personas por completar',
              style: AppTypography.of(context).headingSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Selecciona varias personas y elige desde qué mes empiezan. No se deducen deudas de su fecha de alta.',
              style: AppTypography.of(context).bodyMedium,
            ),
            if (pending.hasError)
              AppButton(
                label: 'Reintentar',
                variant: AppButtonVariant.ghost,
                onPressed: () =>
                    ref.invalidate(firstMonthCandidatesProvider(groupId)),
              ),
            if (pending.hasValue &&
                !pending.isLoading &&
                !pending.hasError) ...[
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Completar primer mes',
                leadingIcon: Icons.playlist_add_check_rounded,
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).push<void>(
                      AppPageTransitions.formRoute(
                        context,
                        FirstMonthSetupScreen(groupId: groupId),
                      ),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FirstMonthSetupScreen extends ConsumerStatefulWidget {
  const FirstMonthSetupScreen({super.key, required this.groupId});
  final String groupId;
  @override
  ConsumerState<FirstMonthSetupScreen> createState() =>
      _FirstMonthSetupScreenState();
}

class _FirstMonthSetupScreenState extends ConsumerState<FirstMonthSetupScreen> {
  final _guard = GlobalKey<AppFormGuardState>();
  final _selected = <String>{};
  late YearMonth _month;
  @override
  void initState() {
    super.initState();
    _month = ref.read(quotaMonthProvider(widget.groupId));
  }

  Future<void> _save() async {
    final ids = Set<String>.of(_selected);
    final month = _month;
    final confirmed = await AppDialog.show(
      context,
      title: '¿Confirmar estos primeros meses?',
      description:
          '${ids.length} personas participarán desde $month, incluido. Sus cuotas dependerán de las reglas del grupo; no se marca ningún mes como pagado. Cada persona se guarda por separado; si algo falla se indicarán las ya completadas.',
      confirmLabel: 'Guardar primeros meses',
      variant: AppDialogVariant.confirmation,
    );
    if (!mounted || !confirmed) return;
    final result = await ref
        .read(firstMonthSetupProvider(widget.groupId).notifier)
        .save(ids, month);
    if (!mounted || result == null) return;
    setState(() => _selected.removeAll(result.completedIds));
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.groupId;
    final action = ref.watch(firstMonthSetupProvider(id));
    final allowed = ref.watch(canManagePersonsProvider(id));
    final candidates = ref.watch(firstMonthCandidatesProvider(id));
    final result = action.asData?.value;
    return AppFormGuard(
      key: _guard,
      busy: action.isLoading,
      isDirty: () => _selected.isNotEmpty,
      child: AppScaffold(
        maxWidth: AppSpacing.readingMax,
        appBar: AppTopBar(
          title: 'Completar primeros meses',
          leading: AppIconButton(
            icon: Icons.arrow_back_rounded,
            label: 'Volver a personas',
            onPressed: () => _guard.currentState?.requestExit(),
          ),
        ),
        child: !allowed
            ? const EmptyState(
                icon: Icons.lock_outline,
                title: 'Acceso no disponible',
                description: 'Necesitas permiso de gestión.',
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Un mes, varias personas.',
                    style: AppTypography.of(context).editorialTitle,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Solo aparecen personas activas que aún no tienen ninguna etapa. No se modifican periodos existentes ni se reactiva a nadie.',
                    style: AppTypography.of(context).bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppMonthField(
                    label: 'Primer mes incluido',
                    value: _month.firstDayUtc,
                    lastYear: ref.watch(quotaMonthProvider(id)).year,
                    enabled: !action.isLoading,
                    onChanged: (date) =>
                        setState(() => _month = YearMonth.fromDate(date)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (candidates.isLoading)
                    const LoadingIndicator(label: 'Comprobando personas…'),
                  if (candidates.hasError)
                    Text(failureMessage(candidates.error!)),
                  if (!candidates.isLoading &&
                      !candidates.hasError &&
                      candidates.hasValue) ...[
                    if (candidates.requireValue.isEmpty)
                      const Text(
                        'Todas las personas activas tienen su primer mes configurado.',
                      ),
                    if (candidates.requireValue.isNotEmpty) ...[
                      AppButton(
                        label: 'Seleccionar todas',
                        variant: AppButtonVariant.outline,
                        onPressed: action.isLoading
                            ? null
                            : () => setState(() {
                                _selected.clear();
                                _selected.addAll(
                                  candidates.requireValue.map((p) => p.id),
                                );
                              }),
                      ),
                      AppButton(
                        label: 'Quitar selección',
                        variant: AppButtonVariant.ghost,
                        onPressed: action.isLoading
                            ? null
                            : () => setState(_selected.clear),
                      ),
                      for (final person in candidates.requireValue)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(person.displayName),
                          value: _selected.contains(person.id),
                          onChanged: action.isLoading
                              ? null
                              : (checked) => setState(() {
                                  if (checked == true) {
                                    _selected.add(person.id);
                                  } else {
                                    _selected.remove(person.id);
                                  }
                                }),
                        ),
                    ],
                  ],
                  if (action.hasError) Text(failureMessage(action.error!)),
                  if (result != null)
                    AppCard(
                      child: Text(
                        '${result.completedIds.length} personas guardadas.${result.error == null ? '' : ' Se detuvo en ${result.failedName}: ${failureMessage(result.error!)}. Revisa los datos antes de reintentar.'}',
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Revisar selección (${_selected.length})',
                    leadingIcon: Icons.check_rounded,
                    loading: action.isLoading,
                    onPressed:
                        action.isLoading ||
                            _selected.isEmpty ||
                            candidates.isLoading ||
                            candidates.hasError
                        ? null
                        : _save,
                  ),
                ],
              ),
      ),
    );
  }
}
