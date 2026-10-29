import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/models/economic_report.dart';
import 'package:bote_parroquial/models/group.dart';
import 'package:bote_parroquial/models/group_member.dart';
import 'package:bote_parroquial/models/movement.dart';
import 'package:bote_parroquial/models/report_export.dart';
import 'package:bote_parroquial/repositories/csv_export_repository.dart';
import 'package:bote_parroquial/services/file_sharing_service.dart';
import 'package:bote_parroquial/services/native_report_file_service.dart';
import 'package:bote_parroquial/services/xlsx_report_encoder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

class _Sharing extends Fake implements FileSharingService {}

void main() {
  final repository = CsvExportRepository(_Sharing());
  final group = Group(
    id: 'a',
    name: 'Parroquia & comunidad',
    currency: 'EUR',
    timeZone: 'Europe/Madrid',
    isActive: true,
    createdBy: 'alice',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  final member = GroupMember(
    groupId: 'a',
    uid: 'alice',
    displayName: 'Ana',
    role: GroupRole.owner,
    isActive: true,
    joinedAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  Movement row(int index, {String groupId = 'a'}) => Movement(
    id: 'movement-$index',
    groupId: groupId,
    input: MovementInput(
      type: MovementType.withdrawal,
      amountCents: 2050,
      occurredAt: DateTime.utc(2026, 10, 15),
      description: '=HYPERLINK("host") & <hola> Peña $index',
    ),
    status: index == 0 ? MovementStatus.cancelled : MovementStatus.active,
    createdBy: 'alice',
    createdAt: DateTime.utc(2026, 10, 15),
    updatedAt: DateTime.utc(2026, 10, 15),
  );
  ReportExport prepare(List<Movement> rows) => repository.prepare(
    'alice',
    group,
    member,
    [],
    rows,
    {'alice': 'Ana'},
    const ReportSelection(year: 2026, month: 10),
  );
  test('XLSX conserva estados, céntimos, textos y estructura sin fórmulas', () {
    final data = prepare([row(0), row(1)]);
    final zip = ZipDecoder().decodeBytes(
      const XlsxReportEncoder().encode(data),
    );
    final xml = {
      for (final file in zip.files)
        file.name: XmlDocument.parse(utf8.decode(file.content)),
    };
    expect(
      xml['xl/workbook.xml']!
          .findAllElements('sheet')
          .map((e) => e.getAttribute('name')),
      ['Resumen', 'Personas', 'Movimientos', 'Actividad mensual'],
    );
    final sheet = xml['xl/worksheets/sheet3.xml']!;
    expect(sheet.findAllElements('f'), isEmpty);
    expect(
      sheet.findAllElements('t').map((e) => e.innerText),
      contains('=HYPERLINK("host") & <hola> Peña 1'),
    );
    expect(
      sheet
          .findAllElements('v')
          .map((e) => e.innerText)
          .where((v) => v == '2050')
          .length,
      2,
    );
    final summary = xml['xl/worksheets/sheet1.xml']!;
    expect(
      summary.findAllElements('v').map((e) => e.innerText),
      contains('-2050'),
    );
    final csv = utf8.decode(repository.encode(data).bytes);
    expect(csv, contains("'=HYPERLINK"));
    expect(csv, contains('cancelled'));
    // Excel would round a 16-digit integer: preserve its exact representation as text.
    final large = ReportExport(
      baseName: data.baseName,
      groupName: data.groupName,
      currency: data.currency,
      report: data.report,
      movementRows: [
        ['Exacto'],
        [9007199254740993],
      ],
    );
    final largeZip = ZipDecoder().decodeBytes(
      const XlsxReportEncoder().encode(large),
    );
    final largeSheet = XmlDocument.parse(
      utf8.decode(largeZip.findFile('xl/worksheets/sheet3.xml')!.content),
    );
    expect(
      largeSheet.findAllElements('t').map((e) => e.innerText),
      contains('9007199254740993'),
    );
  });
  test(
    'PDF completo genera varias páginas con fuente local y no altera dinero',
    () async {
      final data = prepare([for (var i = 0; i < 100; i++) row(i)]);
      final font = await File(
        'assets/fonts/Manrope-Variable.ttf',
      ).readAsBytes();
      final bytes = await encodeReportPdf(data, font);
      expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
      expect(
        RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(bytes)).length,
        greaterThan(1),
      );
      expect(data.report.closingCents, -202950);
    },
  );
  test('Todos los formatos comparten la denegación por UID o alcance', () {
    expect(
      () => repository.prepare(
        'bob',
        group,
        member,
        [],
        [row(1)],
        {},
        const ReportSelection(year: 2026, month: 10),
      ),
      throwsA(isA<AppFailure>()),
    );
    expect(
      () => prepare([row(1, groupId: 'other')]),
      throwsA(isA<AppFailure>()),
    );
  });
}
