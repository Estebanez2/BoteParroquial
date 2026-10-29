import '../models/daily_snapshot.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/movement.dart';
import '../models/movement_cash_totals.dart';
import '../models/person.dart';
import '../models/participation_period.dart';
import '../models/quota_allocation.dart';
import '../models/quota_rule.dart';
import '../models/refund_plan.dart';
import '../models/year_month.dart';
import '../services/movement_service.dart';
import '../services/movement_dashboard_source.dart';
import '../services/group_quota_service.dart';

/// Pure interpretation of a coherent, immutable copy. No Flutter or SDKs.
class SnapshotDataRepository {
  SnapshotDataRepository(this.snapshot) {
    for (final doc in snapshot.documents) {
      _data[doc.path] = decodeFields(doc.fields);
    }
    // Eagerly validate core projections before presenting a "complete" copy.
    for (final group in groups) {
      if (!members(group.id).any((m) => m.uid == snapshot.uid && m.isActive)) {
        throw DailySnapshot.invalid;
      }
      persons(group.id);
      movements(group.id);
      rules(group.id);
      periods(group.id);
      allocations(group.id);
      if (rows(
        'groups/${group.id}',
        'notifications',
      ).any((r) => r.data['recipientUid'] != snapshot.uid)) {
        throw DailySnapshot.invalid;
      }
    }
  }
  final DailySnapshot snapshot;
  final _data = <String, Map<String, Object?>>{};
  bool canReadManagement(String groupId) {
    final member = members(
      groupId,
    ).where((m) => m.uid == snapshot.uid && m.isActive).firstOrNull;
    if (member == null) return false;
    if (member.role == GroupRole.owner) return true;
    return member.role == GroupRole.admin &&
        persons(groupId).any(
          (p) =>
              p.id == member.personId &&
              p.linkedUid == snapshot.uid &&
              p.isActive,
        );
  }

  static Object? decode(Object? raw) {
    if (raw is! Map || raw.length != 1) throw DailySnapshot.invalid;
    if (raw.containsKey('nullValue')) return null;
    if (raw['integerValue'] case final String value) {
      final n = BigInt.parse(value);
      if (BigInt.from(n.toInt()) != n) throw DailySnapshot.invalid;
      return n.toInt();
    }
    if (raw.containsKey('booleanValue')) return raw['booleanValue'] as bool;
    for (final field in ['stringValue', 'timestampValue', 'referenceValue']) {
      if (raw.containsKey(field)) return raw[field] as String;
    }
    if (raw['mapValue'] case final Map map) {
      return decodeFields(
        Map<String, Object?>.from(map['fields'] as Map? ?? {}),
      );
    }
    if (raw['arrayValue'] case final Map array) {
      return (array['values'] as List? ?? []).map(decode).toList();
    }
    throw DailySnapshot.invalid;
  }

  static Map<String, Object?> decodeFields(Map<String, Object?> fields) =>
      fields.map((k, v) => MapEntry(k, decode(v)));
  Map<String, Object?>? data(String path) => _data[path];
  List<({String id, Map<String, Object?> data})> rows(
    String parent,
    String collection,
  ) => [
    for (final entry in _data.entries)
      if (entry.key.startsWith('$parent/$collection/') &&
          entry.key.split('/').length == parent.split('/').length + 2)
        (id: entry.key.split('/').last, data: entry.value),
  ];
  DateTime _date(Map d, String key) => DateTime.parse(d[key] as String).toUtc();
  YearMonth _month(Object? n) {
    if (n is! int || n < 24000 || n > 25211) throw DailySnapshot.invalid;
    return YearMonth(n ~/ 12, n % 12 + 1);
  }

  List<Group> get groups => [
    for (final id in snapshot.groupIds)
      if (_data['groups/$id'] case final Map d)
        Group(
          id: id,
          name: d['name'],
          description: d['description'],
          currency: d['currency'],
          timeZone: d['timeZone'],
          isActive: d['isActive'],
          createdBy: d['createdBy'],
          createdAt: _date(d, 'createdAt'),
          updatedAt: _date(d, 'updatedAt'),
        ),
  ];
  List<GroupMember> members(String group) =>
      rows('groups/$group', 'members').map((row) {
        final d = row.data;
        if (d['uid'] != row.id) throw DailySnapshot.invalid;
        return GroupMember(
          groupId: group,
          uid: row.id,
          displayName: d['displayName'] as String,
          role: GroupRole.values.byName(d['role'] as String),
          isActive: d['status'] == 'active',
          personId: d['personId'] as String?,
          joinedAt: _date(d, 'joinedAt'),
          updatedAt: _date(d, 'updatedAt'),
        );
      }).toList();
  List<Person> persons(String group) =>
      rows(
          'groups/$group',
          'persons',
        ).where((r) => r.data['trashedAt'] == null).map((row) {
          final d = row.data;
          return Person(
            id: row.id,
            groupId: group,
            displayName: d['displayName'] as String,
            notes: d['notes'] as String?,
            isActive: d['isActive'] as bool,
            linkedUid: d['linkedUid'] as String?,
            lastParticipationPeriodId:
                d['lastParticipationPeriodId'] as String?,
            createdBy: d['createdBy'] as String,
            updatedBy: d['updatedBy'] as String,
            createdAt: _date(d, 'createdAt'),
            updatedAt: _date(d, 'updatedAt'),
          );
        }).toList()
        ..sort(
          (a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
        );
  List<Movement> movements(
    String group,
  ) => rows('groups/$group', 'movements').map((row) {
    final d = row.data;
    return Movement(
      id: row.id,
      groupId: group,
      input: MovementInput(
        type: MovementType.values.byName(d['type'] as String),
        amountCents: d['amountCents'] as int,
        description: d['description'] as String,
        personId: d['personId'] as String?,
        occurredAt: _date(d, 'occurredAt'),
        refund: RefundPlan.fromMap(d['refund']),
      ),
      status: MovementStatus.values.byName(d['status'] as String),
      createdBy: d['createdBy'] as String,
      createdAt: _date(d, 'createdAt'),
      updatedAt: _date(d, 'updatedAt'),
      cancelledBy: d['cancelledBy'] as String?,
      cancelledAt: d['cancelledAt'] == null ? null : _date(d, 'cancelledAt'),
      cancellationReason: d['cancellationReason'] as String?,
      correctedBy: d['correctedBy'] as String?,
      correctedAt: d['correctedAt'] == null ? null : _date(d, 'correctedAt'),
      correctionReason: d['correctionReason'] as String?,
      correctedByMovementId: d['correctedByMovementId'] as String?,
      correctionOfMovementId: d['correctionOfMovementId'] as String?,
    );
  }).toList();
  List<QuotaRule> rules(String group, {String? ruleId}) =>
      rows(
        ruleId == null ? 'groups/$group' : 'groups/$group/quotaRules/$ruleId',
        ruleId == null ? 'quotaRules' : 'versions',
      ).map((row) {
        final d = row.data;
        return QuotaRule(
          id: row.id,
          groupId: group,
          effectiveFrom: _month(d['effectiveFromMonth']),
          monthlyFeeCents: d['monthlyFeeCents'] as int,
          revision: d['revision'] as int,
        );
      }).toList();
  List<ParticipationPeriod> periods(String group) =>
      rows('groups/$group', 'participationPeriods').map((row) {
        final d = row.data;
        return ParticipationPeriod(
          id: row.id,
          groupId: group,
          personId: d['personId'] as String,
          firstMonth: _month(d['firstMonth']),
          lastMonthInclusive: d['lastMonthInclusive'] == null
              ? null
              : _month(d['lastMonthInclusive']),
        );
      }).toList();
  List<QuotaAllocation> allocations(String group) =>
      rows('groups/$group', 'allocations').map((row) {
        final d = row.data;
        return QuotaAllocation(
          id: row.id,
          groupId: group,
          movementId: d['movementId'] as String,
          personId: d['personId'] as String,
          month: _month(d['month']),
          amountCents: d['amountCents'] as int,
          revision: d['revision'] as int,
          participationPeriodId: d['participationPeriodId'] as String,
        );
      }).toList();
}

class SnapshotMovementService
    implements MovementService, MovementDashboardSource {
  const SnapshotMovementService(this.data);
  final SnapshotDataRepository data;
  @override
  Stream<List<Movement>> watchMovements(String groupId) =>
      Stream.value(data.movements(groupId));
  @override
  Future<List<Movement>> loadMovements(String groupId) async =>
      data.movements(groupId);
  @override
  Stream<List<Movement>> watchRecent(String groupId) => watchMovements(groupId);
  @override
  Stream<List<Movement>> watchQuotaSources(String groupId) =>
      watchMovements(groupId);
  @override
  Future<void> clearCashAccount(String uid) async {}
  @override
  Stream<MovementCashTotals> watchCash(
    String groupId,
    String uid,
    DateTime monthStart,
  ) {
    if (uid != data.snapshot.uid) throw snapshotReadOnlyFailure;
    int sum(MovementType type, bool monthly) {
      final exact = data
          .movements(groupId)
          .where(
            (m) =>
                m.status == MovementStatus.active &&
                m.input.type == type &&
                (!monthly ||
                    (m.input.occurredAt.year == monthStart.year &&
                        m.input.occurredAt.month == monthStart.month)),
          )
          .fold<BigInt>(
            BigInt.zero,
            (n, m) => n + BigInt.from(m.input.amountCents),
          );
      if (BigInt.from(exact.toInt()) != exact) throw DailySnapshot.invalid;
      return exact.toInt();
    }

    final totals = MovementCashTotals(
      groupId: groupId,
      monthStart: monthStart,
      incomeCents: sum(MovementType.income, false),
      withdrawalCents: sum(MovementType.withdrawal, false),
      monthIncomeCents: sum(MovementType.income, true),
      monthWithdrawalCents: sum(MovementType.withdrawal, true),
      confirmedAt: data.snapshot.asOf,
      cached: true,
    );
    totals.validate(groupId, monthStart);
    return Stream.value(totals);
  }

  @override
  String newId(String groupId) => throw snapshotReadOnlyFailure;
  @override
  Future<void> save(
    String groupId,
    String id,
    String actorUid,
    MovementInput input, {
    Movement? original,
    String? reason,
  }) async => throw snapshotReadOnlyFailure;
  @override
  Future<void> cancel(
    String groupId,
    Movement movement,
    String actorUid,
    String reason,
  ) async => throw snapshotReadOnlyFailure;
}

class SnapshotQuotaService implements GroupQuotaService {
  const SnapshotQuotaService(this.data);
  final SnapshotDataRepository data;
  @override
  Stream<List<ParticipationPeriod>> watchPeriods(String groupId) =>
      Stream.value(data.periods(groupId));
  @override
  Stream<List<QuotaAllocation>> watchAllocations(String groupId) =>
      Stream.value(data.allocations(groupId));
}
