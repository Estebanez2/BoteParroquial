import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/audit_labels.dart';
import '../../../design_system/design_system.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/audit_history_providers.dart';
import '../providers/group_management_providers.dart';

class AuditEventDetail extends ConsumerWidget {
  const AuditEventDetail({
    super.key,
    required this.groupId,
    required this.eventId,
    required this.currency,
    required this.expectedUid,
  });
  final String groupId, eventId, currency, expectedUid;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(canEditGroupProvider(groupId)) ||
        ref.watch(authStateProvider).asData?.value?.uid != expectedUid) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Detalle no disponible',
        description: 'Tu sesión o tus permisos han cambiado.',
      );
    }
    final history = ref.watch(auditHistoryProvider(groupId));
    final matches = history.events.where((event) => event.id == eventId);
    if (matches.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        title: 'Evento no disponible',
        description: 'Vuelve al historial y actualiza la consulta.',
      );
    }
    final event = matches.single;
    final actors = ref.watch(auditActorsProvider(groupId));
    final t = AppTypography.of(context);
    final locale = MaterialLocalizations.of(context);
    final date = event.createdAt.toLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBadge(auditActionLabels[event.action] ?? 'Cambio administrativo'),
        const SizedBox(height: AppSpacing.md),
        Text(
          actors[event.actorUid] ?? 'Usuario no disponible',
          style: t.headingSmall,
        ),
        Text(
          '${locale.formatMediumDate(date)} · ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(date), alwaysUse24HourFormat: true)} · Hora de este móvil',
          style: t.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppAdaptiveRow(
          children: [
            _Values(title: 'Antes', values: event.before, currency: currency),
            _Values(title: 'Después', values: event.after, currency: currency),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppExpandableRow(
          title: const Text('Identificadores del registro'),
          children: [
            SelectableText(
              'Evento: ${event.id}\nAcción: ${event.action}\nAutor: ${event.actorUid}\nEntidad: ${event.entityType}/${event.entityId}\nGrupo: ${event.groupId}',
              style: t.bodySmall,
            ),
          ],
        ),
        AppButton(
          label: 'Cerrar detalle',
          variant: AppButtonVariant.outline,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _Values extends StatelessWidget {
  const _Values({
    required this.title,
    required this.values,
    required this.currency,
  });
  final String title, currency;
  final Map<String, Object?>? values;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppTypography.of(context).headingSmall),
        const SizedBox(height: AppSpacing.md),
        Text(
          values == null ? 'No existía' : auditDetailsText(values!, currency),
          style: AppTypography.of(context).bodyMedium,
        ),
      ],
    ),
  );
}

String auditDetailsText(Map<String, Object?> values, String currency) {
  const labels = {
    'name': 'Nombre',
    'description': 'Descripción',
    'enabled': 'Invitación activa',
    'requiresApproval': 'Requiere aprobación',
    'regenerated': 'Código renovado',
    'displayName': 'Persona',
    'uid': 'Identificador de cuenta',
    'status': 'Estado',
    'role': 'Rol',
    'personId': 'Persona vinculada',
    'linkedUid': 'Cuenta vinculada',
    'ownerUid': 'Cuenta propietaria',
    'effectiveFromMonth': 'Mes de inicio',
    'monthlyFeeCents': 'Cuota',
    'amountCents': 'Importe',
    'occurredAt': 'Fecha efectiva',
    'type': 'Tipo de movimiento',
    'incomeId': 'Ingreso de origen',
    'month': 'Mes asignado',
    'movementId': 'Movimiento',
    'revision': 'Versión',
    'periodId': 'Periodo',
    'firstMonth': 'Primer mes',
    'lastMonthInclusive': 'Último mes incluido',
    'groupName': 'Grupo confirmado',
    'isActive': 'Persona activa',
  };
  String text(Object? value) => switch (value) {
    true => 'Sí',
    false => 'No',
    null => 'Sin asignar',
    'pending' => 'Pendiente',
    'approved' => 'Aprobado',
    'rejected' => 'Rechazado',
    'active' => 'Activo',
    'inactive' => 'Inactivo',
    'owner' => 'Propietario',
    'admin' => 'Administrador',
    'member' => 'Miembro',
    'income' => 'Ingreso',
    'withdrawal' => 'Retirada',
    DateTime date => '${date.toUtc().toIso8601String()} (UTC)',
    _ => '$value',
  };
  return values.entries
      .map((entry) {
        final value = entry.value;
        final rendered =
            ['monthlyFeeCents', 'amountCents'].contains(entry.key) &&
                value is int
            ? formatMoneyCents(value, currency: currency)
            : [
                    'effectiveFromMonth',
                    'month',
                    'firstMonth',
                    'lastMonthInclusive',
                  ].contains(entry.key) &&
                  value is int
            ? '${value ~/ 12}-${(value % 12 + 1).toString().padLeft(2, '0')}'
            : text(value);
        return '${labels[entry.key] ?? entry.key}: $rendered';
      })
      .join('\n');
}
