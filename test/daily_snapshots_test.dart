import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bote_parroquial/core/firebase/firebase_providers.dart';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:bote_parroquial/models/appearance_settings.dart';
import 'package:flutter/material.dart' show Brightness;
import 'package:bote_parroquial/features/dashboard/providers/dashboard_providers.dart';
import 'package:bote_parroquial/features/movements/providers/movement_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_management_providers.dart';
import 'package:bote_parroquial/features/offline/providers/snapshot_session_providers.dart';
import 'package:bote_parroquial/features/reports/providers/quota_report_providers.dart';
import 'package:bote_parroquial/models/daily_snapshot.dart';
import 'package:bote_parroquial/models/dashboard_summary.dart';
import 'package:bote_parroquial/repositories/daily_snapshot_repository.dart';
import 'package:bote_parroquial/repositories/snapshot_data_repository.dart';
import 'package:bote_parroquial/services/daily_snapshot_service.dart';
import 'package:bote_parroquial/services/file_snapshot_storage.dart';
import 'package:bote_parroquial/services/firestore_snapshot_service.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:bote_parroquial/features/offline/presentation/snapshot_browser_screen.dart';

const _time = '2026-10-23T09:00:00.000Z';
Object wire(Object? value) {
  if (value == null) return {'nullValue': null};
  if (value is bool) return {'booleanValue': value};
  if (value is int) return {'integerValue': '$value'};
  if (value is String) {
    return value == _time ? {'timestampValue': value} : {'stringValue': value};
  }
  if (value is Map) {
    return {
      'mapValue': {'fields': value.map((k, v) => MapEntry(k, wire(v)))},
    };
  }
  throw StateError('Fixture value');
}

DailySnapshot fixture({String day = '2026-10-23'}) {
  final records = <String, Map<String, Object?>>{};
  void add(String path, Map<String, Object?> data) => records[path] = data;
  final meta = {
    'createdBy': 'alice',
    'updatedBy': 'alice',
    'createdAt': _time,
    'updatedAt': _time,
  };
  add('users/alice', {
    'displayName': 'Ana',
    'createdAt': _time,
    'updatedAt': _time,
  });
  add('groups/a', {
    'name': 'DEMO guardado',
    'currency': 'EUR',
    'timeZone': 'Europe/Madrid',
    'isActive': true,
    ...meta,
  });
  add('groups/a/members/alice', {
    'uid': 'alice',
    'displayName': 'Ana',
    'role': 'owner',
    'status': 'active',
    'personId': 'p',
    'joinedAt': _time,
    'updatedAt': _time,
  });
  add('groups/a/persons/p', {
    'displayName': 'Ana',
    'isActive': true,
    'linkedUid': 'alice',
    'lastParticipationPeriodId': 'stage',
    ...meta,
  });
  for (final item in [
    ('income', 'income', 10000),
    ('expense', 'withdrawal', 1000),
    ('refund', 'withdrawal', 500),
  ]) {
    add('groups/a/movements/${item.$1}', {
      'type': item.$2,
      'amountCents': item.$3,
      'personId': item.$1 == 'expense' ? null : 'p',
      'status': 'active',
      'description': 'DEMO',
      'occurredAt': _time,
      ...meta,
      if (item.$1 == 'refund')
        'refund': {
          'incomeId': 'income',
          'unallocatedCents': 0,
          'parts': {'24321': 500},
        },
    });
  }
  add('groups/a/quotaRules/24321', {
    'effectiveFromMonth': 24321,
    'monthlyFeeCents': 2000,
    'revision': 1,
    ...meta,
  });
  add('groups/a/participationPeriods/stage', {
    'personId': 'p',
    'firstMonth': 24321,
    'lastMonthInclusive': null,
    ...meta,
  });
  for (final month in [24321, 24322]) {
    add('groups/a/allocations/income_$month', {
      'movementId': 'income',
      'personId': 'p',
      'month': month,
      'amountCents': 2000,
      'revision': 1,
      'participationPeriodId': 'stage',
      ...meta,
    });
  }
  return DailySnapshot(
    uid: 'alice',
    day: day,
    readTime: _time,
    savedAt: DateTime.parse(_time),
    documents: [
      for (final r in records.entries)
        SnapshotDocument(r.key, r.value.map((k, v) => MapEntry(k, wire(v)))),
    ],
  );
}

class _Remote implements SnapshotRemoteSource {
  _Remote(this.copy);
  final DailySnapshot copy;
  Completer<DailySnapshot>? pending;
  bool fail = false;
  bool emptyAccess = false;
  int captures = 0;
  @override
  Future<Map<String, String>> access(String uid) async => emptyAccess
      ? {}
      : {
          'a': snapshotAccessStamp(
            copy.documents.firstWhere(
              (d) => d.path == 'groups/a/members/alice',
            ),
          ),
        };
  @override
  Future<DailySnapshot> capture(String uid, String day) async {
    captures++;
    if (fail) throw const AppFailure(FailureCode.network, 'offline');
    return pending == null ? copy : pending!.future;
  }
}

void main() {
  late Directory directory;
  late FileSnapshotStorage storage;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bote-copy-test-');
    storage = FileSnapshotStorage(
      directory: () async => directory,
      key: (_) async => SecretKey(List.filled(32, 7)),
    );
  });
  tearDown(() async {
    expect(
      directory.absolute.uri.path.startsWith(
        Directory.systemTemp.absolute.uri.resolve('bote-copy-test-').path,
      ),
      true,
    );
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test(
    'Cifrado autenticado, siete días, aislamiento y descarga incompleta conservan copias',
    () async {
      for (var day = 10; day <= 17; day++) {
        await storage.save(fixture(day: '2026-10-$day'));
      }
      expect((await storage.list('alice')).map((e) => e.day), [
        '2026-10-17',
        '2026-10-16',
        '2026-10-15',
        '2026-10-14',
        '2026-10-13',
        '2026-10-12',
        '2026-10-11',
      ]);
      expect(await storage.list('bob'), isEmpty);
      final files = await directory
          .list(recursive: true)
          .where((e) => e is File)
          .cast<File>()
          .toList();
      expect(files.length, 7);
      expect(
        await files.first.readAsString(),
        isNot(contains('DEMO guardado')),
      );
      final original = await storage.load('alice', '2026-10-17');
      expect(original.documents.length, fixture().documents.length);
      await expectLater(
        storage.save(fixture(day: '2026-10-17')),
        throwsA(isA<FileSystemException>()),
      );
      final remote = _Remote(fixture())..fail = true,
          repo = DailySnapshotRepository(storage, remote, () => 'alice');
      await expectLater(
        repo.refresh('alice', '2026-10-23'),
        throwsA(isA<AppFailure>()),
      );
      expect((await storage.list('alice')).length, 7);
      final target = files.first,
          bytes = await target.readAsString(),
          box = jsonDecode(bytes) as Map;
      final cipher = base64Decode(box['ciphertext']);
      cipher[0] ^= 1;
      box['ciphertext'] = base64Encode(cipher);
      await target.writeAsString(jsonEncode(box));
      expect(
        (await storage.list('alice')).length,
        6,
      ); // Never display corrupted data.
    },
  );

  test(
    'Una descarga de una sesión anterior no reaparece tras salir; revocación elimina el grupo',
    () async {
      var uid = 'alice';
      final copy = fixture(), remote = _Remote(copy)..pending = Completer();
      final repo = DailySnapshotRepository(storage, remote, () => uid);
      final task = repo.refresh('alice', '2026-10-23');
      await Future<void>.delayed(const Duration(milliseconds: 25));
      uid = 'bob';
      await repo.clear('alice');
      remote.pending!.complete(copy);
      await task;
      expect(await storage.list('alice'), isEmpty);
      await storage.save(copy);
      await storage.restrict('alice', {});
      expect(await storage.list('alice'), isEmpty);
      final firstLogin = _Remote(copy)..emptyAccess = true;
      final joining = DailySnapshotRepository(
        storage,
        firstLogin,
        () => 'alice',
      );
      await joining.refresh('alice', copy.day);
      expect(firstLogin.captures, 0);
      firstLogin.emptyAccess = false;
      await joining.refresh('alice', copy.day);
      expect(firstLogin.captures, 1);
      await joining.refresh('alice', copy.day);
      expect(firstLogin.captures, 1);
    },
  );

  test(
    'Lector completo usa readTime estable, pagina y no acepta otra cuenta o privilegio cambiado',
    () async {
      final copy = fixture(),
          root = 'projects/test/databases/(default)/documents/';
      var noticePages = 0,
          pages = 0,
          queries = 0,
          memberPasses = 0,
          changed = false,
          deniedRoot = false;
      final service = FirestoreSnapshotService(
        currentUid: () => 'alice',
        request: (action, body) async {
          queries++;
          if (action == ':batchGet') {
            final path = (body['documents'] as List).single;
            if (deniedRoot && path == 'groups/a') {
              throw const AppFailure(
                FailureCode.permissionDenied,
                'Grupo ya no autorizado',
              );
            }
            final doc = copy.documents.where((d) => d.path == path).firstOrNull;
            return [
              if (doc != null)
                {
                  'found': {'name': '$root${doc.path}', 'fields': doc.fields},
                  'readTime': _time,
                }
              else
                {'missing': '$root$path', 'readTime': _time},
            ];
          }
          final q = body['structuredQuery'] as Map,
              from = (q['from'] as List).single as Map;
          if (q['limit'] == 1) {
            return [
              {'readTime': _time},
            ];
          }
          expect(body['readTime'], _time);
          final collection = from['collectionId'];
          final parent = action.substring(0, action.indexOf(':'));
          var docs = copy.documents
              .where(
                (d) => from['allDescendants'] == true
                    ? d.path == 'groups/a/members/alice'
                    : d.path.startsWith('$parent/$collection/') &&
                          d.path.split('/').length ==
                              parent.split('/').length + 2,
              )
              .toList();
          if (collection == 'members' && from['allDescendants'] == true) {
            memberPasses++;
          }
          if (collection == 'members' &&
              from['allDescendants'] == true &&
              changed &&
              memberPasses.isEven) {
            docs = [
              SnapshotDocument(docs.single.path, {
                ...docs.single.fields,
                'role': {'stringValue': 'member'},
              }),
            ];
          }
          if (collection == 'movements') {
            pages++;
            docs = q['startAt'] == null
                ? List.generate(
                    200,
                    (i) => SnapshotDocument(
                      'groups/a/movements/page-$i',
                      docs.first.fields,
                    ),
                  )
                : docs;
          }
          if (collection == 'notifications') {
            expect(q['limit'], 50);
            noticePages++;
            docs = List.generate(
              q['startAt'] == null ? 50 : 1,
              (i) => SnapshotDocument(
                'groups/a/notifications/notice-${q['startAt'] == null ? i : 50}',
                {
                  'recipientUid': wire('alice'),
                  'kind': wire('quotaReminder'),
                  'title': wire('DEMO aviso'),
                  'body': wire('DEMO'),
                  'createdAt': wire(_time),
                  'readAt': wire(null),
                },
              ),
            );
          }
          return [
            for (final d in docs)
              {
                'document': {'name': '$root${d.path}', 'fields': d.fields},
                'readTime': _time,
              },
            if (docs.isEmpty) {'readTime': _time},
          ];
        },
      );
      final captured = await service.capture('alice', '2026-10-23');
      expect(pages, 2);
      expect(noticePages, 2);
      expect(
        captured.documents
            .where((d) => d.path.startsWith('groups/a/notifications/'))
            .length,
        51,
      );
      expect(
        captured.documents.where((d) => d.path.contains('/movements/')).length,
        203,
      );
      expect(queries, greaterThan(10));
      changed = true;
      memberPasses = 0;
      await expectLater(
        service.capture('alice', '2026-10-23'),
        throwsA(isA<AppFailure>()),
      );
      changed = false;
      deniedRoot = true;
      expect(await service.access('alice'), isEmpty);
      expect((await service.capture('alice', '2026-10-23')).groupIds, isEmpty);
      await expectLater(
        service.capture('bob', '2026-10-23'),
        throwsA(isA<AppFailure>()),
      );
      // No application credential or delivery token can enter the format.
      expect(
        () => DailySnapshot(
          uid: 'alice',
          day: copy.day,
          readTime: _time,
          savedAt: copy.savedAt,
          documents: [SnapshotDocument('users/bob', {})],
        ),
        throwsA(isA<AppFailure>()),
      );
    },
  );

  test(
    'Mismas proyecciones de dashboard/cuotas; Firebase y escrituras quedan bloqueados',
    () async {
      final data = SnapshotDataRepository(fixture()),
          container = createSnapshotContainer(data);
      addTearDown(container.dispose);
      final done = Completer<DashboardSummary>();
      final sub = container.listen(dashboardProvider('a'), (_, next) {
        if (next.hasValue && !done.isCompleted) {
          done.complete(next.requireValue);
        }
      }, fireImmediately: true);
      addTearDown(sub.close);
      final result = await done.future.timeout(const Duration(seconds: 5));
      expect(result.balanceCents, 8500);
      final quotas = Completer<void>();
      final qsub = container.listen(dashboardQuotaReportProvider('a'), (
        _,
        next,
      ) {
        if (next.hasValue && !quotas.isCompleted) {
          expect(next.requireValue.elapsed.totals.expectedCents, 2000);
          expect(next.requireValue.elapsed.totals.pendingCents, 500);
          quotas.complete();
        }
      }, fireImmediately: true);
      addTearDown(qsub.close);
      await quotas.future.timeout(const Duration(seconds: 5));
      expect(container.read(canEditGroupProvider('a')), false);
      expect(
        () => container.read(firestoreProvider),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.exception,
            'cause',
            isA<AppFailure>(),
          ),
        ),
      );
      await expectLater(
        container
            .read(movementRepositoryProvider)
            .cancel('a', data.movements('a').first, 'alice', 'DEMO'),
        throwsA(isA<AppFailure>()),
      );
    },
  );

  testWidgets(
    'La copia abre el dashboard habitual y conserva aviso fijo y acciones bloqueadas',
    (tester) async {
      Future<void> settleCopy() async {
        // Let the private cache's actual filesystem futures complete between
        // frames; an animated placeholder cannot settle while fake I/O is held.
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 250));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
        }
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(
        SnapshotSessionView(
          data: SnapshotDataRepository(fixture()),
          onExit: () {},
          appearanceTheme: AppTheme.forPalette(
            AppPalette.coral,
            Brightness.dark,
          ),
        ),
      );
      await settleCopy();
      expect(find.text('COPIA GUARDADA · SOLO LECTURA'), findsOneWidget);
      expect(find.text('Datos actuales'), findsOneWidget);
      expect(
        tester.getSize(find.byType(AppReadOnlyBanner)).height,
        lessThan(120),
      );
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pump();
      expect(tester.takeException(), isNull);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.pump();
      await tester.ensureVisible(find.text('Entrar en el grupo guardado'));
      await tester.tap(find.text('Entrar en el grupo guardado'));
      await settleCopy();
      expect(find.text('BoteParroquial'), findsOneWidget);
      expect(
        AppColors.of(tester.element(find.text('BoteParroquial'))).primary,
        AppColors.forPalette(AppPalette.coral, Brightness.dark).primary,
      );
      expect(find.text('Registrar ingreso'), findsNothing);
      expect(find.text('COPIA GUARDADA · SOLO LECTURA'), findsOneWidget);
      await tester.tap(find.text('Actividad'));
      await settleCopy();
      expect(find.text('Historial de movimientos'), findsOneWidget);
      expect(find.text('Registrar ingreso'), findsNothing);
      expect(find.text('COPIA GUARDADA · SOLO LECTURA'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settleCopy();
      expect(find.text('BoteParroquial'), findsOneWidget);
      await tester.tap(find.text('Participantes').last);
      await settleCopy();
      expect(find.text('Ver personas'), findsOneWidget);
      expect(find.text('Ver miembros'), findsOneWidget);
      expect(find.text('COPIA GUARDADA · SOLO LECTURA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
