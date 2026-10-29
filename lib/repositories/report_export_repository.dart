import '../models/economic_report.dart';
import '../models/export_file.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/movement.dart';
import '../models/person.dart';
import '../models/report_export.dart';
import '../services/report_file_service.dart';
import 'csv_export_repository.dart';

class ReportExportRepository {
  const ReportExportRepository(this._csv, this._files);
  final CsvExportRepository _csv;
  final ReportFileService _files;

  Future<ExportFile> build(
    String uid,
    Group group,
    GroupMember member,
    List<Person> persons,
    List<Movement> movements,
    Map<String, String> authors,
    ReportSelection selection,
    ReportExportFormat format,
  ) async {
    // One permission/scope/filter implementation for all three formats.
    final data = _csv.prepare(
      uid,
      group,
      member,
      persons,
      movements,
      authors,
      selection,
    );
    return format == ReportExportFormat.csv
        ? _csv.encode(data)
        : _files.generate(data, format);
  }
}
