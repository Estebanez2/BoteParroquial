import '../models/export_file.dart';

abstract interface class FileSharingService {
  Future<FileShareOutcome> share(String uid, ExportFile file);
  Future<void> clearAccount(String uid);
  Future<void> copyText(String text);
  Future<void> shareText(String text);
}
