import 'economic_report.dart';

enum ReportExportFormat { csv, pdf, xlsx }

/// An authorized, immutable value snapshot. No SDK objects or credentials.
class ReportExport {
  ReportExport({
    required this.baseName,
    required this.groupName,
    required this.currency,
    required this.report,
    required List<List<Object?>> movementRows,
  }) : movementRows = List.unmodifiable(
         movementRows.map((row) => List<Object?>.unmodifiable(row)),
       );
  final String baseName, groupName, currency;
  final EconomicReport report;
  final List<List<Object?>> movementRows;
}
