import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../models/export_file.dart';
import '../../../models/report_export.dart';
import '../../../repositories/csv_export_repository.dart';
import '../../../repositories/report_export_repository.dart';
import '../../../services/native_report_file_service.dart';
import '../../../services/native_file_sharing_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../groups/providers/group_management_providers.dart';
import '../../groups/providers/group_providers.dart';
import '../../movements/providers/movement_providers.dart';
import '../../persons/providers/person_providers.dart';
import 'report_providers.dart';

final csvExportRepositoryProvider = Provider((ref) {
  final repository = CsvExportRepository(NativeFileSharingService());
  var uid = ref.read(authStateProvider).asData?.value?.uid;
  ref.listen(authStateProvider, (_, next) {
    if (next.isLoading) return;
    final current = next.asData?.value?.uid;
    if (uid != null && current != uid) unawaited(repository.clearAccount(uid!));
    uid = current;
  });
  return repository;
});
final csvExportProvider = NotifierProvider.autoDispose
    .family<CsvExportController, AsyncValue<void>, String>(
      CsvExportController.new,
    );
final reportExportFormatProvider = NotifierProvider.autoDispose
    .family<ReportExportFormatController, ReportExportFormat, String>(
      ReportExportFormatController.new,
    );

class ReportExportFormatController extends Notifier<ReportExportFormat> {
  ReportExportFormatController(this.groupId);
  final String groupId;
  @override
  ReportExportFormat build() => ReportExportFormat.pdf;
  void select(ReportExportFormat value) => state = value;
}

class CsvExportController extends Notifier<AsyncValue<void>> {
  CsvExportController(this.groupId);
  final String groupId;
  @override
  AsyncValue<void> build() => const AsyncData(null);
  Future<FileShareOutcome?> export() async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    try {
      final uid = ref.read(authStateProvider).asData?.value?.uid;
      final group = ref.read(groupProvider(groupId)).asData?.value;
      final selection = ref.read(reportSelectionProvider(groupId));
      if (uid == null ||
          group == null ||
          !ref.read(canEditGroupProvider(groupId))) {
        throw const AppFailure(
          FailureCode.permissionDenied,
          'No tienes permiso para exportar este grupo.',
        );
      }
      final repository = ref.read(csvExportRepositoryProvider);
      final loader = ref.read(movementRepositoryProvider);
      final people = await ref.read(personsProvider(groupId).future);
      final movements = await loader.loadMovements(groupId);
      if (!ref.mounted ||
          ref.read(authStateProvider).asData?.value?.uid != uid ||
          !ref.read(canEditGroupProvider(groupId))) {
        throw const AppFailure(
          FailureCode.cancelled,
          'Tu sesión o permisos han cambiado; no se ha exportado.',
        );
      }
      final member = ref.read(currentMembershipProvider(groupId));
      if (member == null) {
        throw const AppFailure(
          FailureCode.permissionDenied,
          'No tienes acceso al grupo.',
        );
      }
      final file =
          await ReportExportRepository(
            repository,
            NativeReportFileService(),
          ).build(
            uid,
            group,
            member,
            people,
            movements,
            ref.read(movementLabelsProvider(groupId)).authors,
            selection,
            ref.read(reportExportFormatProvider(groupId)),
          );
      if (!ref.mounted ||
          ref.read(authStateProvider).asData?.value?.uid != uid ||
          !ref.read(canEditGroupProvider(groupId))) {
        throw const AppFailure(
          FailureCode.cancelled,
          'Tu sesión o permisos han cambiado; no se ha compartido el archivo.',
        );
      }
      final result = await repository.share(uid, file);
      if (ref.mounted) state = const AsyncData(null);
      return result;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return null;
    }
  }
}
