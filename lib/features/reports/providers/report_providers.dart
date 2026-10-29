import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../models/economic_report.dart';
import '../../../repositories/economic_report_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../groups/providers/group_providers.dart';
import '../../movements/providers/movement_providers.dart';
import '../../persons/providers/person_providers.dart';

final economicReportRepositoryProvider = Provider(
  (ref) => const EconomicReportRepository(),
);
final reportSelectionProvider = NotifierProvider.autoDispose
    .family<ReportSelectionController, ReportSelection, String>(
      ReportSelectionController.new,
    );

class ReportSelectionController extends Notifier<ReportSelection> {
  ReportSelectionController(this.groupId);
  final String groupId;
  @override
  ReportSelection build() {
    ref.watch(authStateProvider.select((state) => state.asData?.value?.uid));
    final zone = ref.watch(
      groupProvider(groupId).select((state) => state.asData?.value?.timeZone),
    );
    if (zone == null) {
      // This inert selection is never used by a visible report without group
      // access. Avoid an unhandled Notifier rebuild error during revocation.
      return const ReportSelection(year: 2000, month: 1);
    }
    final day = ref.watch(groupCalendarRepositoryProvider).today(zone);
    return ReportSelection(year: day.year, month: day.month);
  }

  void select({int? year, int? month, ReportPeriod? period}) =>
      state = ReportSelection(
        year: year ?? state.year,
        month: month ?? state.month,
        period: period ?? state.period,
      );
  int currentYear() {
    final zone = ref.read(groupProvider(groupId)).requireValue?.timeZone;
    if (zone == null) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'Grupo no disponible.',
      );
    }
    return ref.read(groupCalendarRepositoryProvider).today(zone).year;
  }
}

final economicReportProvider = Provider.autoDispose
    .family<AsyncValue<EconomicReport>, String>((ref, groupId) {
      final selection = ref.watch(reportSelectionProvider(groupId));
      final people = ref.watch(personsProvider(groupId));
      final movements = ref.watch(movementsProvider(groupId));
      if (people.isLoading || movements.isLoading) return const AsyncLoading();
      if (people.hasError) {
        return AsyncError(
          people.error!,
          people.stackTrace ?? StackTrace.current,
        );
      }
      if (movements.hasError) {
        return AsyncError(
          movements.error!,
          movements.stackTrace ?? StackTrace.current,
        );
      }
      try {
        return AsyncData(
          ref
              .read(economicReportRepositoryProvider)
              .summarize(
                groupId,
                movements.requireValue,
                people.requireValue,
                selection,
              ),
        );
      } catch (error, stack) {
        return AsyncError(error, stack);
      }
    });

final personFinancialSummaryProvider = Provider.autoDispose
    .family<AsyncValue<PersonFinancialSummary>, (String, String)>((ref, key) {
      final people = ref.watch(personsProvider(key.$1));
      final movements = ref.watch(movementsProvider(key.$1));
      if (people.isLoading || movements.isLoading) return const AsyncLoading();
      if (people.hasError) {
        return AsyncError(
          people.error!,
          people.stackTrace ?? StackTrace.current,
        );
      }
      if (movements.hasError) {
        return AsyncError(
          movements.error!,
          movements.stackTrace ?? StackTrace.current,
        );
      }
      try {
        final matches = people.requireValue.where(
          (person) => person.id == key.$2,
        );
        if (matches.isEmpty) {
          throw const AppFailure(
            FailureCode.invalidData,
            'Esta persona no está disponible en el grupo.',
          );
        }
        return AsyncData(
          ref
              .read(economicReportRepositoryProvider)
              .personSummary(key.$1, matches.single, movements.requireValue),
        );
      } catch (error, stack) {
        return AsyncError(error, stack);
      }
    });
