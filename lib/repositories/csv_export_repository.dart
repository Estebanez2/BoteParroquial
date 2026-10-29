import 'dart:convert';
import '../core/errors/app_failure.dart';
import '../models/economic_report.dart';
import '../models/export_file.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/movement.dart';
import '../models/movement_history_filter.dart';
import '../models/person.dart';
import '../models/report_export.dart';
import '../services/file_sharing_service.dart';
import 'economic_report_repository.dart';
import 'movement_history_repository.dart';

class CsvExportRepository {
  const CsvExportRepository(this._sharing);
  final FileSharingService _sharing;

  ExportFile build(
    String uid,
    Group group,
    GroupMember member,
    List<Person> persons,
    List<Movement> movements,
    Map<String, String> authors,
    ReportSelection selection,
  ) => encode(
    prepare(uid, group, member, persons, movements, authors, selection),
  );

  ReportExport prepare(
    String uid,
    Group group,
    GroupMember member,
    List<Person> persons,
    List<Movement> movements,
    Map<String, String> authors,
    ReportSelection selection,
  ) {
    final adminLinked =
        member.personId != null &&
        persons.any((p) => p.id == member.personId && p.isActive);
    if (member.uid != uid ||
        member.groupId != group.id ||
        !member.isActive ||
        !group.isActive ||
        !(member.role == GroupRole.owner ||
            (member.role == GroupRole.admin && adminLinked))) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'Solo propietarios y administradores autorizados pueden exportar desde la aplicación.',
      );
    }
    final report = const EconomicReportRepository().summarize(
      group.id,
      movements,
      persons,
      selection,
    );
    final rows = const MovementHistoryRepository().filter(
      group.id,
      movements,
      MovementHistoryFilter(
        fromDate: report.start,
        toDate: report.endExclusive.subtract(const Duration(days: 1)),
      ),
    );
    final names = {for (final person in persons) person.id: person.displayName};
    String date(DateTime value) =>
        '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    final data = <List<Object?>>[
      [
        'grupo_id',
        'grupo_nombre',
        'moneda',
        'movimiento_id',
        'tipo',
        'estado',
        'importe_centimos',
        'efecto_saldo_centimos',
        'fecha_efectiva',
        'fecha_registro_utc',
        'persona_id',
        'persona_nombre',
        'creador_uid',
        'creador_nombre',
        'descripcion',
        'motivo_anulacion',
        'motivo_correccion',
        'original_id',
        'sustituto_id',
      ],
      for (final row in rows)
        [
          group.id,
          group.name,
          group.currency,
          row.id,
          row.input.type.name,
          row.status.name,
          row.input.amountCents,
          row.contributionCents,
          date(row.input.occurredAt),
          row.createdAt.toUtc().toIso8601String(),
          row.input.personId,
          row.input.personId == null
              ? 'El grupo'
              : names[row.input.personId] ?? 'Persona no disponible',
          row.createdBy,
          authors[row.createdBy] ?? 'Usuario no disponible',
          row.input.description,
          row.cancellationReason,
          row.correctionReason,
          row.correctionOfMovementId,
          row.correctedByMovementId,
        ],
    ];
    final sanitized = group.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final name = sanitized.length > 64 ? sanitized.substring(0, 64) : sanitized;
    return ReportExport(
      baseName:
          'bote-$name-${date(report.start)}-${date(report.endExclusive.subtract(const Duration(days: 1)))}',
      groupName: group.name,
      currency: group.currency,
      report: report,
      movementRows: data,
    );
  }

  ExportFile encode(ReportExport data) {
    String cell(Object? value) {
      var text = value?.toString() ?? '';
      if (value is String && RegExp(r'^[\s]*[=+@\-\t\r\n]').hasMatch(text)) {
        text = "'$text";
      }
      return '"${text.replaceAll('"', '""')}"';
    }

    return ExportFile(
      name: '${data.baseName}.csv',
      mimeType: 'text/csv',
      bytes: utf8.encode(
        '\uFEFF${data.movementRows.map((row) => row.map(cell).join(';')).join('\r\n')}\r\n',
      ),
    );
  }

  Future<FileShareOutcome> share(String uid, ExportFile file) =>
      _sharing.share(uid, file);
  Future<void> clearAccount(String uid) => _sharing.clearAccount(uid);
}
