import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/design_system.dart';
import '../../../models/movement.dart';
import '../../../models/movement_history_filter.dart';
import '../providers/movement_providers.dart';

class MovementHistoryControls extends ConsumerStatefulWidget {
  const MovementHistoryControls({super.key, required this.groupId});
  final String groupId;

  @override
  ConsumerState<MovementHistoryControls> createState() =>
      _MovementHistoryControlsState();
}

class _MovementHistoryControlsState
    extends ConsumerState<MovementHistoryControls> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(movementFilterProvider(widget.groupId)).query,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _filters() async {
    final provider = movementFilterProvider(widget.groupId);
    final criteria = ref.read(provider);
    final options = ref.read(movementHistoryOptionsProvider(widget.groupId));
    final result = await AppBottomSheet.show<MovementHistoryFilter>(
      context,
      title: 'Afina tu historial',
      builder: (_) => _MovementFiltersSheet(
        initial: criteria,
        options: options,
        validate: ref.read(provider.notifier).validate,
      ),
    );
    if (result != null && mounted) ref.read(provider.notifier).apply(result);
  }

  @override
  Widget build(BuildContext context) {
    final provider = movementFilterProvider(widget.groupId);
    final filter = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final rows = ref
        .watch(movementHistoryProvider((widget.groupId, null)))
        .asData
        ?.value;
    ref.listen(provider, (_, next) {
      if (_search.text != next.query) {
        _search.value = TextEditingValue(
          text: next.query,
          selection: TextSelection.collapsed(offset: next.query.length),
        );
      }
    });
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Buscar en el historial',
            hint: 'Persona, concepto o autor…',
            icon: Icons.search_rounded,
            controller: _search,
            onChanged: controller.search,
            suffix: filter.query.isEmpty
                ? null
                : AppIconButton(
                    icon: Icons.close_rounded,
                    label: 'Limpiar búsqueda',
                    variant: AppIconButtonVariant.ghost,
                    onPressed: () => controller.search(''),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppAdaptiveRow(
            children: [
              AppButton(
                label: filter.criteriaCount == 0
                    ? 'Filtros'
                    : 'Filtros · ${filter.criteriaCount}',
                leadingIcon: Icons.tune_rounded,
                variant: AppButtonVariant.outline,
                onPressed: _filters,
              ),
              if (filter.criteriaCount != 0)
                AppButton(
                  label: 'Limpiar filtros',
                  variant: AppButtonVariant.ghost,
                  onPressed: controller.reset,
                ),
            ],
          ),
          if (rows != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '${rows.length} ${rows.length == 1 ? 'movimiento encontrado' : 'movimientos encontrados'}',
              style: AppTypography.of(context).bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Local form draft; only Apply sends criteria to the history provider.
class _MovementFiltersSheet extends StatefulWidget {
  const _MovementFiltersSheet({
    required this.initial,
    required this.options,
    required this.validate,
  });
  final MovementHistoryFilter initial;
  final MovementHistoryOptions options;
  final String? Function(MovementHistoryFilter) validate;

  @override
  State<_MovementFiltersSheet> createState() => _MovementFiltersSheetState();
}

class _MovementFiltersSheetState extends State<_MovementFiltersSheet> {
  late MovementHistoryFilter _draft = widget.initial;

  @override
  Widget build(BuildContext context) {
    final error = widget.validate(_draft);
    final person = (_draft.groupOnly, _draft.personId);
    final people = <(bool, String?), String>{
      (false, null): 'Todas las personas y el grupo',
      (true, null): 'Solo el grupo · sin persona',
      for (final entry in widget.options.persons.entries)
        (false, entry.key): entry.value,
      if (_draft.personId != null &&
          !widget.options.persons.containsKey(_draft.personId))
        person: 'Persona no disponible',
    };
    final authors = <String, String>{
      '': 'Cualquier creador',
      ...widget.options.authors,
      if (_draft.authorUid != null &&
          !widget.options.authors.containsKey(_draft.authorUid))
        _draft.authorUid!: 'Usuario no disponible',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppReveal(
          child: Text(
            'Encuentra lo que pasó. Las fechas corresponden al día efectivo del dinero, no al día de registro.',
            style: AppTypography.of(context).bodyMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppAdaptiveRow(
          children: [
            AppDropdown<String>(
              label: 'Tipo',
              value: _draft.type?.name ?? '',
              options: const {
                '': 'Todos los tipos',
                'income': 'Ingresos',
                'withdrawal': 'Retiradas',
              },
              onChanged: (value) => setState(
                () => _draft = _draft.copyWith(
                  type: value == 'income'
                      ? MovementType.income
                      : MovementType.withdrawal,
                  clearType: value == '',
                ),
              ),
            ),
            AppDropdown<String>(
              label: 'Estado',
              value: _draft.status?.name ?? '',
              options: const {
                '': 'Todos los estados',
                'active': 'Activos',
                'cancelled': 'Anulados',
                'corrected': 'Corregidos',
              },
              onChanged: (value) => setState(
                () => _draft = _draft.copyWith(
                  status: switch (value) {
                    'active' => MovementStatus.active,
                    'cancelled' => MovementStatus.cancelled,
                    _ => MovementStatus.corrected,
                  },
                  clearStatus: value == '',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppDropdown<(bool, String?)>(
          label: 'Persona',
          value: person,
          options: people,
          onChanged: (value) {
            if (value == null) return;
            setState(
              () => _draft = _draft.copyWith(
                groupOnly: value.$1,
                personId: value.$2,
                clearPerson: value.$2 == null,
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        AppDropdown<String>(
          label: 'Registrado por',
          value: _draft.authorUid ?? '',
          options: authors,
          onChanged: (value) => setState(
            () => _draft = _draft.copyWith(
              authorUid: value,
              clearAuthor: value == '',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppAdaptiveRow(
          children: [
            AppDateField(
              label: 'Desde · fecha efectiva',
              value: _draft.fromDate,
              onChanged: (date) =>
                  setState(() => _draft = _draft.copyWith(fromDate: date)),
            ),
            AppDateField(
              label: 'Hasta · fecha efectiva',
              value: _draft.toDate,
              onChanged: (date) =>
                  setState(() => _draft = _draft.copyWith(toDate: date)),
            ),
          ],
        ),
        if (_draft.fromDate != null || _draft.toDate != null)
          AppButton(
            label: 'Quitar fechas',
            variant: AppButtonVariant.ghost,
            onPressed: () =>
                setState(() => _draft = _draft.copyWith(clearDates: true)),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              error,
              style: AppTypography.of(
                context,
              ).bodyMedium.copyWith(color: AppColors.of(context).danger),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Aplicar filtros',
          leadingIcon: Icons.check_rounded,
          fullWidth: true,
          onPressed: error == null
              ? () => Navigator.pop(context, _draft)
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppAdaptiveRow(
          children: [
            AppButton(
              label: 'Restablecer',
              variant: AppButtonVariant.ghost,
              onPressed: () =>
                  setState(() => _draft = const MovementHistoryFilter()),
            ),
            AppButton(
              label: 'Cancelar',
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ],
    );
  }
}
