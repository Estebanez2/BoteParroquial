import '../models/export_file.dart';
import '../models/report_export.dart';

abstract interface class ReportFileService {
  Future<ExportFile> generate(ReportExport data, ReportExportFormat format);
}
