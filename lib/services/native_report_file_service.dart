import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/errors/app_failure.dart';
import '../models/export_file.dart';
import '../models/report_export.dart';
import 'report_file_service.dart';
import 'xlsx_report_encoder.dart';

class NativeReportFileService implements ReportFileService {
  @override
  Future<ExportFile> generate(
    ReportExport data,
    ReportExportFormat format,
  ) async {
    if (format == ReportExportFormat.csv) throw ArgumentError.value(format);
    // Load bundled font on the root isolate. Encoding/layout runs away from UI.
    final font = format == ReportExportFormat.pdf
        ? (await rootBundle.load(
            'assets/fonts/Manrope-Variable.ttf',
          )).buffer.asUint8List()
        : null;
    try {
      final bytes = await Isolate.run(
        () => format == ReportExportFormat.xlsx
            ? Future.value(const XlsxReportEncoder().encode(data))
            : encodeReportPdf(data, font!),
      );
      return ExportFile(
        name: '${data.baseName}.${format.name}',
        mimeType: format == ReportExportFormat.pdf
            ? 'application/pdf'
            : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        bytes: bytes,
      );
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure(
        FailureCode.unknown,
        'No se pudo generar el informe completo. Prueba un periodo menor o el formato CSV.',
      );
    }
  }
}

Future<List<int>> encodeReportPdf(
  ReportExport data,
  Uint8List fontBytes,
) async {
  final font = pw.Font.ttf(ByteData.sublistView(fontBytes));
  final document = pw.Document(
    title: 'BoteParroquial · ${data.groupName}',
    author: 'BoteParroquial',
  );
  final report = data.report;
  String date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String money(int cents) {
    final exact = BigInt.from(cents).abs();
    return '${cents < 0 ? '-' : ''}${exact ~/ BigInt.from(100)},${(exact % BigInt.from(100)).toString().padLeft(2, '0')} ${data.currency}';
  }

  pw.Widget heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 14)),
  );
  pw.Widget table(List<String> headers, List<List<String>> rows) =>
      pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellStyle: const pw.TextStyle(fontSize: 8),
        headerStyle: const pw.TextStyle(fontSize: 8),
        cellPadding: const pw.EdgeInsets.all(5),
      );
  // Explicit finite guard: never silently omit rows when a document is too large.
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      maxPages: 10000,
      theme: pw.ThemeData.withFont(
        base: font,
        bold: font,
        italic: font,
        boldItalic: font,
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
      build: (_) => [
        pw.Text(data.groupName, style: const pw.TextStyle(fontSize: 24)),
        pw.Text(
          '${date(report.start)} – ${date(report.endExclusive.subtract(const Duration(days: 1)))}',
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Estado actual del historial. Caja por fecha efectiva; este informe no acredita cuotas pagadas.',
          style: const pw.TextStyle(fontSize: 9),
        ),
        heading('Resumen económico'),
        table(
          ['Concepto', 'Importe'],
          [
            ['Saldo inicial', money(report.openingCents)],
            ['Ingresos activos', money(report.incomeCents)],
            ['Retiradas activas', money(report.withdrawalCents)],
            ['Saldo final', money(report.closingCents)],
          ],
        ),
        heading('Actividad mensual'),
        table(
          ['Mes', 'Ingresos', 'Retiradas'],
          [
            for (final month in report.months)
              [
                date(month.month).substring(3),
                money(month.incomeCents),
                money(month.withdrawalCents),
              ],
          ],
        ),
        heading('Por persona · movimientos activos'),
        table(
          ['Persona', 'Estado', 'Ingresos', 'Retiradas'],
          [
            for (final person in report.persons)
              [
                person.name,
                person.isActive ? 'Activa' : 'Inactiva/no disponible',
                money(person.incomeCents),
                money(person.withdrawalCents),
              ],
          ],
        ),
        heading('Movimientos · todos los estados'),
        pw.Text(
          'Los anulados y corregidos se conservan en esta tabla, pero no suman en el resumen.',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 8),
        table(
          [
            'Fecha / ID',
            'Tipo / estado',
            'Persona / concepto / autor',
            'Importe',
          ],
          [
            for (final row in data.movementRows.skip(1))
              [
                '${row[8]}\n${row[3]}',
                '${row[4] == 'income' ? 'Ingreso' : 'Retirada'}\n${switch (row[5]) {
                  'active' => 'Activo',
                  'cancelled' => 'Anulado',
                  _ => 'Corregido',
                }}',
                '${row[11]}\n${row[14] ?? ''}\n${row[13]}',
                money(row[6] as int),
              ],
          ],
        ),
      ],
    ),
  );
  return document.save();
}
