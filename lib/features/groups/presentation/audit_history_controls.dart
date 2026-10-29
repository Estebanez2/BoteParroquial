import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/audit_labels.dart';
import '../../../design_system/design_system.dart';
import '../providers/audit_history_providers.dart';

class AuditHistoryControls extends ConsumerStatefulWidget {
  const AuditHistoryControls({super.key, required this.groupId});
  final String groupId;
  @override
  ConsumerState<AuditHistoryControls> createState() =>
      _AuditHistoryControlsState();
}

class _AuditHistoryControlsState extends ConsumerState<AuditHistoryControls> {
  late final TextEditingController _search;
  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(auditFilterProvider(widget.groupId)).query,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = auditFilterProvider(widget.groupId);
    final criteria = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final actors = ref.watch(auditActorsProvider(widget.groupId));
    ref.listen(provider, (_, next) {
      if (_search.text != next.query) _search.text = next.query;
    });
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Buscar entre cambios cargados',
            hint: 'Acción, autor, entidad o valores…',
            icon: Icons.search_rounded,
            controller: _search,
            onChanged: controller.search,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppAdaptiveRow(
            children: [
              AppDropdown<String>(
                label: 'Tipo de cambio',
                value: criteria.entityType ?? '',
                options: {'': 'Todos', ...auditEntityLabels},
                onChanged: (value) =>
                    controller.entity(value == '' ? null : value),
              ),
              AppDropdown<String>(
                label: 'Autor',
                value: criteria.actorUid ?? '',
                options: {'': 'Todos', ...actors},
                onChanged: (value) =>
                    controller.actor(value == '' ? null : value),
              ),
            ],
          ),
          if (criteria.query.isNotEmpty ||
              criteria.entityType != null ||
              criteria.actorUid != null)
            AppButton(
              label: 'Limpiar búsqueda y filtros',
              variant: AppButtonVariant.ghost,
              onPressed: controller.reset,
            ),
        ],
      ),
    );
  }
}
