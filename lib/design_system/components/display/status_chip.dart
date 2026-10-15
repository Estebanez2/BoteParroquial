import 'package:flutter/material.dart';
import 'app_badge.dart';

/// Visual states only, not persistence enums or permission checks.
enum AppStatus {
  paid,
  pending,
  partial,
  advance,
  admin,
  owner,
  member,
  active,
  inactive,
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final AppStatus status;
  @override
  Widget build(BuildContext context) {
    final (label, tone, icon) = switch (status) {
      AppStatus.paid => ('Pagado', AppTone.success, Icons.check_circle_outline),
      AppStatus.pending => (
        'Pendiente',
        AppTone.warning,
        Icons.schedule_outlined,
      ),
      AppStatus.partial => (
        'Parcial',
        AppTone.warning,
        Icons.timelapse_outlined,
      ),
      AppStatus.advance => (
        'Adelantado',
        AppTone.info,
        Icons.fast_forward_outlined,
      ),
      AppStatus.admin => (
        'Admin',
        AppTone.primary,
        Icons.admin_panel_settings_outlined,
      ),
      AppStatus.owner => (
        'Owner',
        AppTone.primary,
        Icons.verified_user_outlined,
      ),
      AppStatus.member => ('Member', AppTone.neutral, Icons.person_outline),
      AppStatus.active => (
        'Activo',
        AppTone.success,
        Icons.check_circle_outline,
      ),
      AppStatus.inactive => (
        'Inactivo',
        AppTone.neutral,
        Icons.pause_circle_outline,
      ),
    };
    return AppBadge(label, tone: tone, icon: icon);
  }
}
