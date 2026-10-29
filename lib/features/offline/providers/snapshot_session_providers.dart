import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/offline/offline_mode.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../models/auth_user.dart';
import '../../../models/daily_snapshot.dart';
import '../../../models/photo_target.dart';
import '../../../models/year_month.dart';
import '../../../repositories/group_calendar_repository.dart';
import '../../../repositories/movement_repository.dart';
import '../../../repositories/quota_report_repository.dart';
import '../../../repositories/snapshot_data_repository.dart';
import '../../../services/group_clock_service.dart';
import '../../../services/photo_cache_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../groups/providers/group_providers.dart';
import '../../groups/providers/group_management_providers.dart';
import '../../groups/providers/group_invitation_providers.dart';
import '../../groups/providers/group_sync_providers.dart';
import '../../movements/providers/movement_providers.dart';
import '../../persons/providers/person_providers.dart';
import '../../photos/providers/photo_providers.dart';
import '../../quotas/providers/quota_providers.dart';
import '../../quotas/providers/allocation_providers.dart';
import '../../reports/providers/quota_report_providers.dart';

/// Standalone container, never a child of the live app. Unoverridden SDK access
/// fails closed, including mutation repositories reached by a stale/deep link.
ProviderContainer createSnapshotContainer(SnapshotDataRepository data) {
  final cache = PhotoCacheService.persistent(), copy = data.snapshot;
  final clock = TimeZoneGroupClockService(now: () => copy.asOf);
  final people = {for (final g in data.groups) g.id: data.persons(g.id)};
  final targets = <PhotoTarget>{
    PhotoTarget.account(copy.uid),
    for (final g in data.groups) ...[
      PhotoTarget.group(g.id),
      for (final m in data.members(g.id)) PhotoTarget.member(g.id, m.uid),
      for (final p in people[g.id]!) PhotoTarget.person(g.id, p.id),
    ],
  };
  return ProviderContainer(
    overrides: [
      offlineReadOnlyProvider.overrideWithValue(true),
      firebaseAppProvider.overrideWith((_) => throw snapshotReadOnlyFailure),
      firebaseAuthProvider.overrideWith((_) => throw snapshotReadOnlyFailure),
      firestoreProvider.overrideWith((_) => throw snapshotReadOnlyFailure),
      supabaseConnectionProvider.overrideWith(
        (_) => throw snapshotReadOnlyFailure,
      ),
      authStateProvider.overrideWith(
        (_) => Stream.value(AuthUser(uid: copy.uid)),
      ),
      membershipsProvider.overrideWith(
        (_) => Stream.value([
          for (final g in data.groups)
            ...data.members(g.id).where((m) => m.uid == copy.uid && m.isActive),
        ]),
      ),
      groupCalendarRepositoryProvider.overrideWithValue(
        GroupCalendarRepository(clock),
      ),
      movementRepositoryProvider.overrideWithValue(
        MovementRepository(SnapshotMovementService(data)),
      ),
      quotaReportRepositoryProvider.overrideWithValue(
        QuotaReportRepository(SnapshotQuotaService(data)),
      ),
      // PhotoView's lifecycle refresh must never query Supabase from this container.
      photoRefreshProvider.overrideWithValue((_) {}),
      for (final target in targets) ...[
        photoProvider(target).overrideWith((_) async* {
          var value = await cache.load(copy.uid, target);
          if (value?.bytes == null &&
              target.kind == PhotoKind.member &&
              target.id == copy.uid) {
            value = await cache.load(copy.uid, PhotoTarget.account(copy.uid));
          }
          yield value?.bytes;
        }),
        photoPresentationProvider(target).overrideWith((ref) {
          final value = ref.watch(photoProvider(target));
          return (bytes: value.asData?.value, loading: value.isLoading);
        }),
      ],
      for (final group in data.groups) ...[
        groupProvider(group.id).overrideWith((_) => Stream.value(group)),
        groupMembersProvider(
          group.id,
        ).overrideWith((_) => Stream.value(data.members(group.id))),
        personsProvider(
          group.id,
        ).overrideWith((_) => Stream.value(people[group.id]!)),
        canManagePersonsProvider(group.id).overrideWithValue(false),
        canManageMovementsProvider(group.id).overrideWithValue(false),
        canEditGroupProvider(group.id).overrideWithValue(false),
        pendingMovementProvider(group.id).overrideWith((_) async => null),
        groupServerConfirmedProvider(
          group.id,
        ).overrideWith((_) => Stream.value(false)),
        quotaMonthProvider(
          group.id,
        ).overrideWithValue(YearMonth.fromDate(clock.today(group.timeZone))),
        quotaRulesProvider(
          group.id,
        ).overrideWith((_) => Stream.value(data.rules(group.id))),
        groupQuotaPeriodsProvider(
          group.id,
        ).overrideWith((_) => Stream.value(data.periods(group.id))),
        groupQuotaAllocationsProvider(
          group.id,
        ).overrideWith((_) => Stream.value(data.allocations(group.id))),
        for (final member in data.members(group.id))
          canRemoveMemberProvider((group.id, member)).overrideWithValue(false),
        for (final rule in data.rules(group.id))
          quotaVersionsProvider((group.id, rule.id)).overrideWith(
            (_) => Stream.value(data.rules(group.id, ruleId: rule.id)),
          ),
        for (final person in people[group.id]!) ...[
          participationPeriodsProvider((group.id, person.id)).overrideWith(
            (_) => Stream.value(
              data
                  .periods(group.id)
                  .where((p) => p.personId == person.id)
                  .toList(),
            ),
          ),
          allocationsProvider((group.id, person.id)).overrideWith(
            (_) => Stream.value(
              data
                  .allocations(group.id)
                  .where((a) => a.personId == person.id)
                  .toList(),
            ),
          ),
        ],
      ],
    ],
  );
}
