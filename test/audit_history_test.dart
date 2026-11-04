import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bote_parroquial/core/constants/audit_labels.dart';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/design_system/design_system.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/features/groups/presentation/group_audit_screen.dart';
import 'package:bote_parroquial/features/groups/presentation/audit_event_detail.dart';
import 'package:bote_parroquial/features/groups/providers/audit_history_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_management_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_providers.dart';
import 'package:bote_parroquial/features/groups/providers/group_sync_providers.dart';
import 'package:bote_parroquial/features/photos/providers/photo_providers.dart';
import 'package:bote_parroquial/models/audit_history.dart';
import 'package:bote_parroquial/models/group.dart';
import 'package:bote_parroquial/models/group_member.dart';
import 'package:bote_parroquial/repositories/audit_history_repository.dart';
import 'package:bote_parroquial/services/audit_history_service.dart';
import 'package:bote_parroquial/services/firestore_audit_decoder.dart';
import 'auth_flow_test.dart' as auth;

GroupAuditEvent entry(
  int index, {
  String group = 'a',
  String? id,
  int? nanos,
}) => GroupAuditEvent(
  position: AuditCursor(
    groupId: group,
    eventId: id ?? 'e$index',
    seconds: 1792490000,
    nanoseconds: nanos ?? 100000 - index,
  ),
  action: index.isEven ? 'group.updated' : 'quota.changed',
  actorUid: 'alice',
  entityId: group,
  entityType: index.isEven ? 'group' : 'quotaRule',
  before: {'name': 'Antes'},
  after: {'name': 'DEMO cambio $index', 'monthlyFeeCents': 2050},
);

class MemoryAudit implements AuditHistoryService {
  List<GroupAuditEvent> events = List.generate(130, entry);
  final changes = StreamController<AuditPage>.broadcast();
  Completer<AuditPage>? pending;
  int watches = 0, requests = 0;
  AuditPage page(String group, [AuditCursor? after]) {
    final from = after == null
        ? 0
        : events.indexWhere((event) => event.id == after.eventId) + 1;
    final rows = events.skip(from).take(50).toList();
    return AuditPage(
      groupId: group,
      events: rows,
      nextCursor: events.length > from + rows.length
          ? rows.last.position
          : null,
      serverConfirmed: true,
    );
  }

  @override
  Stream<AuditPage> watchHead(String groupId) async* {
    watches++;
    yield page(groupId);
    yield* changes.stream;
  }

  @override
  Future<AuditPage> fetchOlder(String groupId, AuditCursor cursor) async {
    requests++;
    return pending == null ? page(groupId, cursor) : await pending!.future;
  }
}

class _Access extends Notifier<bool> {
  @override
  bool build() => true;
  void deny() => state = false;
}

final _access = NotifierProvider<_Access, bool>(_Access.new);
final group = Group(
  id: 'a',
  name: 'DEMO Auditoría',
  currency: 'EUR',
  timeZone: 'Europe/Madrid',
  isActive: true,
  createdBy: 'alice',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
final member = GroupMember(
  groupId: 'a',
  uid: 'alice',
  displayName: 'Alejandra',
  role: GroupRole.owner,
  isActive: true,
  joinedAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
ProviderContainer setup(MemoryAudit service) => ProviderContainer(
  overrides: [
    authStateProvider.overrideWith((ref) => Stream.value(auth.alice)),
    membershipsProvider.overrideWith((ref) => Stream.value([member])),
    groupProvider.overrideWith(
      (ref, id) => Stream.value(id == 'a' ? group : null),
    ),
    groupMembersProvider.overrideWith((ref, id) => Stream.value([member])),
    canEditGroupProvider.overrideWith(
      (ref, id) => id == 'a' && ref.watch(_access),
    ),
    auditHistoryRepositoryProvider.overrideWithValue(
      AuditHistoryRepository(service),
    ),
    groupServerConfirmedProvider.overrideWith((ref, id) => Stream.value(true)),
    photoPresentationProvider.overrideWith(
      (ref, target) => (bytes: null, loading: false),
    ),
  ],
);
Future<void> ready(ProviderContainer container) async {
  container.read(auditHistoryProvider('a'));
  for (var index = 0; index < 8; index++) {
    await Future<void>.delayed(Duration.zero);
  }
}

GroupAuditEvent decode(String group, Map<String, Object?> values) =>
    decodeAuditEvent(group, 'record', 'groups/a/auditEvents/record', values);

void main() {
  test(
    'Fechas efectivas de movimientos no invalidan toda la página administrativa',
    () async {
      final created = Timestamp(1792490000, 123456789);
      final occurred = Timestamp(1792490000, 0);
      final event = decode('a', {
        'action': 'movement.created',
        'actorUid': 'alice',
        'entityId': 'movement-a',
        'entityType': 'movement',
        'createdAt': created,
        'before': null,
        'after': {'occurredAt': occurred, 'amountCents': 390, 'type': 'income'},
      });
      expect(event.after['occurredAt'], occurred.toDate().toUtc());
      expect(event.position.nanoseconds, 123456789);
      expect(event.after['amountCents'], 390);
      final rendered = auditDetailsText(event.after, 'EUR');
      expect(rendered, contains('Fecha efectiva:'));
      expect(rendered, contains('(UTC)'));
      expect(rendered, contains('Ingreso'));
      final service = MemoryAudit()..events = [event];
      final repository = AuditHistoryRepository(service);
      final page = await repository.watchHead('a').first;
      expect(page.events.single.action, 'movement.created');
      await service.changes.close();
    },
  );
  test(
    'Cursor exacto, grupos, orden, búsqueda española y contratos antiguos/nuevos',
    () async {
      final service = MemoryAudit();
      final repository = AuditHistoryRepository(service);
      addTearDown(service.changes.close);
      final head = await AuditHistoryRepository(service).watchHead('a').first;
      final second = await AuditHistoryRepository(
        service,
      ).fetchOlder('a', head.nextCursor!);
      expect(second.events.first.id, 'e50');
      expect(
        second.events.first.createdAt,
        head.events.last.createdAt,
      ); // same microsecond
      expect(second.events.first.position.nanoseconds, 99950);
      expect(repository.append('a', head.events, second).length, 100);
      expect(
        () => repository.append('a', head.events, head),
        throwsA(isA<AppFailure>()),
      );
      expect(
        () => repository.filter('other', head.events, const AuditFilter()),
        throwsA(isA<AppFailure>()),
      );
      expect(
        repository
            .filter(
              'a',
              head.events,
              const AuditFilter(query: 'ALEJANDRA cuota'),
              actors: {'alice': 'Alejándra'},
              actionLabels: auditActionLabels,
            )
            .length,
        25,
      );
      final emoji = entry(0, id: '😀', nanos: 100),
          private = entry(1, id: '\uE000', nanos: 100);
      expect(
        AuditHistoryRepository.compare(emoji.position, private.position),
        lessThan(0),
      );
      final values = <String, Object?>{
        'action': 'group.created',
        'actorUid': 'alice',
        'entityId': 'a',
        'createdAt': Timestamp(1792490000, 123456789),
        'before': null,
        'after': {'name': 'DEMO'},
      };
      final legacy = decode('a', values);
      expect(legacy.entityType, 'group');
      expect(legacy.position.nanoseconds, 123456789);
      expect(
        () => decode('a', {
          ...values,
          'after': {
            'nested': {'bad': true},
          },
        }),
        throwsA(isA<AppFailure>()),
      );
      expect(() => decode('other', values), throwsA(isA<AppFailure>()));
    },
  );

  test(
    'Páginas estables, doble pulsación, cambios nuevos y descarte de una respuesta tras revocar acceso',
    () async {
      final service = MemoryAudit();
      final scope = setup(service);
      final subscription = scope.listen(auditHistoryProvider('a'), (_, _) {});
      addTearDown(() async {
        subscription.close();
        scope.dispose();
        await service.changes.close();
      });
      await ready(scope);
      expect(scope.read(auditHistoryProvider('a')).events.length, 50);
      final controller = scope.read(auditHistoryProvider('a').notifier);
      final head = service.page('a');
      service.changes.add(
        AuditPage(
          groupId: 'a',
          events: head.events,
          nextCursor: head.nextCursor,
          serverConfirmed: false,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await controller.loadMore();
      expect(service.requests, 0);
      service.changes.add(head);
      await Future<void>.delayed(Duration.zero);
      service.pending = Completer<AuditPage>();
      final request = controller.loadMore();
      await controller.loadMore();
      expect(service.requests, 1);
      final older = service.page(
        'a',
        scope.read(auditHistoryProvider('a')).nextCursor,
      );
      service.events = [entry(-1), ...service.events];
      service.changes.add(service.page('a'));
      await Future<void>.delayed(Duration.zero);
      expect(scope.read(auditHistoryProvider('a')).hasNewChanges, true);
      expect(scope.read(auditHistoryProvider('a')).events.first.id, 'e0');
      service.pending!.complete(older);
      await request;
      expect(scope.read(auditHistoryProvider('a')).events.length, 100);
      controller.refresh();
      await ready(scope);
      expect(scope.read(auditHistoryProvider('a')).events.first.id, 'e-1');
      expect(scope.read(auditHistoryProvider('a')).events.length, 50);
      expect(scope.read(auditHistoryProvider('a')).hasNewChanges, false);
      final latePage = service.page(
        'a',
        scope.read(auditHistoryProvider('a')).nextCursor,
      );
      service.pending = Completer<AuditPage>();
      final late = controller.loadMore();
      scope.read(_access.notifier).deny();
      await ready(scope);
      expect(scope.read(auditHistoryProvider('a')).events, isEmpty);
      service.pending!.complete(latePage);
      await late;
      expect(scope.read(auditHistoryProvider('a')).events, isEmpty);
      expect(scope.read(filteredAuditProvider('a')), isEmpty);
    },
  );

  testWidgets(
    'Historial y detalle accesibles; consulta antigua, búsqueda y revocación en ambos temas',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1100);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final service = MemoryAudit();
      final scope = setup(service);
      addTearDown(() async {
        scope.dispose();
        await service.changes.close();
      });
      Future<void> pump(ThemeMode mode) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              home: const GroupAuditScreen(groupId: 'a'),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pump(ThemeMode.dark);
      expect(find.text('50 cambios cargados'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'cambio 129');
      await tester.pumpAndSettle();
      expect(
        find.text('Sin coincidencias entre los cambios cargados'),
        findsOneWidget,
      );
      for (var index = 0; index < 2; index++) {
        await tester.ensureVisible(find.text('Cargar más cambios'));
        await tester.tap(find.text('Cargar más cambios'));
        await tester.pumpAndSettle();
      }
      expect(scope.read(filteredAuditProvider('a')).single.id, 'e129');
      await tester.ensureVisible(find.text('Ver detalle'));
      await tester.tap(find.text('Ver detalle'));
      await tester.pumpAndSettle();
      expect(find.text('Detalle del cambio'), findsOneWidget);
      expect(find.textContaining('20,50'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await pump(ThemeMode.light);
      expect(tester.takeException(), isNull);
      scope.read(_access.notifier).deny();
      await tester.pumpAndSettle();
      expect(find.text('Detalle no disponible'), findsOneWidget);
      expect(find.textContaining('DEMO cambio 129'), findsNothing);
      expect(scope.read(auditHistoryProvider('a')).events, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
