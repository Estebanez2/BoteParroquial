import 'dart:convert';
import 'dart:io';
import '../core/errors/app_failure.dart';
import '../models/daily_snapshot.dart';
import 'daily_snapshot_service.dart';
import 'group_clock_service.dart';

typedef SnapshotRequest =
    Future<List<Map<String, Object?>>> Function(
      String action,
      Map<String, Object?> body,
    );

/// User JWT only. No service account, Firestore writes or privileged collections.
class FirestoreSnapshotService
    implements SnapshotRemoteSource, SnapshotServerClock {
  FirestoreSnapshotService({required this.request, required this.currentUid});
  final SnapshotRequest request;
  final String? Function() currentUid;
  @override
  String? currentDay;
  String _serverDay(String time) => TimeZoneGroupClockService(
    now: () => DateTime.parse(time),
  ).today('Europe/Madrid').toIso8601String().substring(0, 10);
  static const unavailable = AppFailure(
    FailureCode.network,
    'No se pudo completar la copia. Se conserva la anterior; reintenta con conexión.',
  );
  void _actor(String uid) {
    if (currentUid() != uid) throw snapshotReadOnlyFailure;
  }

  Map<String, Object?> _field(String name, String value) => {
    'fieldFilter': {
      'field': {'fieldPath': name},
      'op': 'EQUAL',
      'value': {'stringValue': value},
    },
  };
  Future<(List<SnapshotDocument>, String)> _query(
    String parent,
    String collection, {
    String? time,
    Map<String, Object?>? filter,
    bool descendants = false,
  }) async {
    final found = <SnapshotDocument>[];
    // Inbox rules cap each query at 50, even when it would return zero.
    final pageSize = collection == 'notifications' ? 50 : 200;
    String? cursor, readTime = time;
    while (true) {
      final rows = await request('$parent:runQuery', {
        'readTime': ?time,
        'structuredQuery': {
          'from': [
            {'collectionId': collection, 'allDescendants': descendants},
          ],
          'where': ?filter,
          'orderBy': [
            {
              'field': {'fieldPath': '__name__'},
              'direction': 'ASCENDING',
            },
          ],
          if (cursor != null)
            'startAt': {
              'values': [
                {'referenceValue': cursor},
              ],
              'before': false,
            },
          'limit': pageSize,
        },
      });
      var count = 0;
      for (final row in rows) {
        if (row['readTime'] is String) readTime = row['readTime'] as String;
        final raw = row['document'];
        if (raw == null) continue;
        if (raw is! Map || raw['name'] is! String || raw['fields'] is! Map) {
          throw DailySnapshot.invalid;
        }
        final name = raw['name'] as String, marker = '/documents/';
        final index = name.indexOf(marker);
        if (index < 0) throw DailySnapshot.invalid;
        final path = name.substring(index + marker.length);
        if (!(descendants
            ? path.split('/').length == 4 && path.split('/')[2] == collection
            : path.startsWith('$parent/$collection/') &&
                  path.split('/').length ==
                      parent.split('/').where((p) => p.isNotEmpty).length +
                          2)) {
          throw DailySnapshot.invalid;
        }
        found.add(
          SnapshotDocument(
            path,
            Map<String, Object?>.from(raw['fields'] as Map),
          ),
        );
        cursor = name;
        count++;
      }
      if (found.length > 100000) throw DailySnapshot.invalid;
      if (count < pageSize) break;
      time = readTime; // All later pages retain the first server readTime.
    }
    if (readTime == null) throw DailySnapshot.invalid;
    return (found, readTime);
  }

  Future<SnapshotDocument?> _get(String path, String time) async {
    final rows = await request(':batchGet', {
      'documents': [path],
      'readTime': time,
    });
    for (final row in rows) {
      final raw = row['found'];
      if (raw is Map) {
        if (raw['name'] is! String ||
            !(raw['name'] as String).endsWith('/documents/$path')) {
          throw DailySnapshot.invalid;
        }
        return SnapshotDocument(
          path,
          Map<String, Object?>.from(raw['fields'] as Map),
        );
      }
    }
    return null;
  }

  String? _str(SnapshotDocument d, String key) =>
      (d.fields[key] as Map?)?['stringValue'] as String?;
  bool _bool(SnapshotDocument d, String key) =>
      (d.fields[key] as Map?)?['booleanValue'] == true;
  Future<(List<SnapshotDocument>, String)> _memberships(String uid) async {
    final rows = await request(':runQuery', {
      'structuredQuery': {
        'from': [
          {'collectionId': 'members', 'allDescendants': true},
        ],
        'where': _field('uid', uid),
        'limit': 1,
      },
    });
    final time = rows.lastOrNull?['readTime'];
    if (time is! String) throw DailySnapshot.invalid;
    return _query(
      '',
      'members',
      time: time,
      descendants: true,
      filter: _field('uid', uid),
    );
  }

  String _stamp(SnapshotDocument member) => jsonEncode({
    'role': member.fields['role'],
    'personId': member.fields['personId'],
    'updatedAt': member.fields['updatedAt'],
  });
  @override
  Future<Map<String, String>> access(String uid) async {
    _actor(uid);
    final (rows, time) = await _memberships(uid);
    final result = <String, String>{};
    for (final member in rows.where((d) => _str(d, 'status') == 'active')) {
      final id = member.path.split('/')[1];
      SnapshotDocument? root;
      try {
        root = await _get('groups/$id', time);
      } on AppFailure catch (e) {
        if (e.code == FailureCode.permissionDenied) continue;
        rethrow;
      }
      if (root != null && _bool(root, 'isActive')) result[id] = _stamp(member);
    }
    _actor(uid);
    currentDay = _serverDay(time);
    return result;
  }

  @override
  Future<DailySnapshot> capture(String uid, String day) async {
    _actor(uid);
    final (memberships, time) = await _memberships(uid);
    if (_serverDay(time) != day) throw unavailable;
    final documents = <SnapshotDocument>[], expected = <String, String>{};
    final profile = await _get('users/$uid', time);
    if (profile != null) documents.add(profile);
    documents.addAll(
      (await _query('users/$uid', 'auditEvents', time: time)).$1,
    );
    for (final member in memberships.where(
      (d) => _str(d, 'status') == 'active',
    )) {
      _actor(uid);
      final id = member.path.split('/')[1], parent = 'groups/$id';
      SnapshotDocument? root;
      try {
        root = await _get(parent, time);
      } on AppFailure catch (e) {
        if (e.code == FailureCode.permissionDenied) continue;
        rethrow;
      }
      if (root == null || !_bool(root, 'isActive')) continue;
      expected[id] = _stamp(member);
      documents.add(root);
      final people = (await _query(parent, 'persons', time: time)).$1;
      documents.addAll(people);
      final ownPerson = people
          .where((p) => p.id == _str(member, 'personId'))
          .firstOrNull;
      final manager =
          _str(member, 'role') == 'owner' ||
          (_str(member, 'role') == 'admin' &&
              ownPerson != null &&
              _bool(ownPerson, 'isActive') &&
              _str(ownPerson, 'linkedUid') == uid);
      for (final collection in [
        'members',
        'movements',
        'quotaRules',
        'participationPeriods',
        'allocations',
        'allocationBalances',
        if (manager) 'auditEvents',
        if (manager) 'joinRequests',
      ]) {
        documents.addAll((await _query(parent, collection, time: time)).$1);
        _actor(uid);
      }
      documents.addAll(
        (await _query(
          parent,
          'notifications',
          time: time,
          filter: _field('recipientUid', uid),
        )).$1,
      );
      for (final path in [
        '$parent/quotaSettings/current',
        '$parent/invitationSettings/current',
        for (final category in ['reminders', 'economic', 'informative'])
          '$parent/members/$uid/notificationPreferences/$category',
      ]) {
        final doc = await _get(path, time);
        if (doc != null) documents.add(doc);
      }
      for (final rule
          in documents
              .where(
                (d) =>
                    d.path.startsWith('$parent/quotaRules/') &&
                    d.path.split('/').length == 4,
              )
              .toList()) {
        documents.addAll((await _query(rule.path, 'versions', time: time)).$1);
      }
      if (documents.length > 100000) throw DailySnapshot.invalid;
    }
    // Do not publish historical privileges when access changed while downloading.
    final actual = await access(uid);
    if (jsonEncode(actual) != jsonEncode(expected)) throw unavailable;
    _actor(uid);
    return DailySnapshot(
      uid: uid,
      day: day,
      readTime: time,
      savedAt: DateTime.now().toUtc(),
      documents: documents,
    );
  }
}

/// REST transport keeps exact int64 wrappers and caps responses. Credentials are
/// fetched per call, kept only in memory, and never stored in a snapshot.
class SnapshotRestTransport {
  const SnapshotRestTransport(this.projectId, this.token);
  final String projectId;
  final Future<String?> Function() token;
  Future<List<Map<String, Object?>>> call(
    String action,
    Map<String, Object?> body,
  ) async {
    final jwt = await token();
    if (jwt == null) throw FirestoreSnapshotService.unavailable;
    final root = 'projects/$projectId/databases/(default)/documents';
    final http = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final suffix = action.startsWith(':') ? action : '/$action';
      final uri = Uri.https('firestore.googleapis.com', '/v1/$root$suffix');
      // batchGet takes fully-qualified paths; no caller controls an origin.
      final payload = {...body};
      if (payload['documents'] case final List paths) {
        payload['documents'] = paths.map((p) => '$root/$p').toList();
      }
      final req = await http.postUrl(uri).timeout(const Duration(seconds: 15));
      req.followRedirects = false;
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $jwt');
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(payload));
      final response = await req.close().timeout(const Duration(seconds: 20));
      if ([401, 403].contains(response.statusCode)) {
        throw const AppFailure(
          FailureCode.permissionDenied,
          'No se pudo autorizar la lectura de estos datos.',
        );
      }
      if (response.statusCode == 429) {
        throw firestoreQuotaFailure;
      }
      if (response.statusCode != 200) {
        throw FirestoreSnapshotService.unavailable;
      }
      final bytes = <int>[];
      await for (final part in response.timeout(const Duration(seconds: 20))) {
        bytes.addAll(part);
        if (bytes.length > 32 * 1024 * 1024) throw DailySnapshot.invalid;
      }
      final data = jsonDecode(utf8.decode(bytes));
      if (data is! List || data.any((r) => r is! Map || r['error'] != null)) {
        throw DailySnapshot.invalid;
      }
      return data.map((r) => Map<String, Object?>.from(r as Map)).toList();
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw FirestoreSnapshotService.unavailable;
    } finally {
      http.close(force: true);
    }
  }
}
