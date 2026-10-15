import 'dart:io';
import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/models/movement.dart';
import 'package:bote_parroquial/models/pending_movement.dart';
import 'package:bote_parroquial/repositories/movement_repository.dart';
import 'package:bote_parroquial/repositories/movement_submission_repository.dart';
import 'package:bote_parroquial/services/file_pending_movement_service.dart';
import 'package:bote_parroquial/services/group_clock_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'movements_test.dart' as fixtures;

class InterruptedMovements extends fixtures.MemoryMovements {
  bool beforeWrite = false;
  bool offlineRead = false;
  static const failure = AppFailure(
    FailureCode.network,
    'Resultado desconocido',
  );
  @override
  Future<List<Movement>> loadMovements(String groupId) async {
    if (offlineRead) throw failure;
    return super.loadMovements(groupId);
  }

  @override
  Future<void> save(
    String groupId,
    String id,
    String uid,
    MovementInput input, {
    Movement? original,
    String? reason,
  }) async {
    if (beforeWrite) throw failure;
    await super.save(
      groupId,
      id,
      uid,
      input,
      original: original,
      reason: reason,
    );
    throw failure;
  }

  @override
  Future<void> cancel(
    String groupId,
    Movement movement,
    String uid,
    String reason,
  ) async {
    await super.cancel(groupId, movement, uid, reason);
    throw failure;
  }
}

MovementInput input(int cents) => MovementInput(
  type: MovementType.income,
  amountCents: cents,
  occurredAt: DateTime.utc(2025),
  description: 'Prueba',
  personId: 'p',
);

void main() {
  late Directory directory;
  late InterruptedMovements service;
  FilePendingMovementService storage() =>
      FilePendingMovementService(directory: () async => directory);
  MovementSubmissionRepository repository() =>
      MovementSubmissionRepository(storage(), MovementRepository(service));
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bote-recovery-');
    service = InterruptedMovements();
  });
  tearDown(() async {
    await service.changes.close();
    expect(directory.absolute.parent.path, Directory.systemTemp.absolute.path);
    await directory.delete(recursive: true);
  });
  test(
    'Reabrir recupera registro, corrección y anulación ya confirmados sin repetir dinero',
    () async {
      var repo = repository();
      var submission = PendingMovement(
        groupId: 'a',
        actorUid: 'alice',
        id: 'one',
        input: input(2050),
      );
      await expectLater(repo.submit(submission), throwsA(isA<AppFailure>()));
      repo =
          repository(); // New repository and disk adapter, as after process death.
      final restored = await repo.pending('alice', 'a');
      expect(restored?.input.amountCents, 2050);
      expect(await repo.pending('bob', 'a'), isNull);
      expect(await repo.pending('alice', 'b'), isNull);
      expect(await repo.resolve(restored!), isTrue);
      expect(service.current.length, 1);
      expect(await repo.pending('alice', 'a'), isNull);

      submission = PendingMovement(
        groupId: 'a',
        actorUid: 'alice',
        id: 'two',
        input: input(3000),
        original: service.current.single,
        reason: 'Corregir importe',
      );
      await expectLater(repo.submit(submission), throwsA(isA<AppFailure>()));
      repo = repository();
      expect(await repo.resolve((await repo.pending('alice', 'a'))!), isTrue);
      expect(service.current.length, 2);
      expect(MovementRepository.balanceOf(service.current), 3000);

      final active = service.current.last;
      submission = PendingMovement(
        groupId: 'a',
        actorUid: 'alice',
        id: active.id,
        input: active.input,
        original: active,
        reason: 'Anular',
        cancel: true,
      );
      await expectLater(repo.submit(submission), throwsA(isA<AppFailure>()));
      repo = repository();
      expect(await repo.resolve((await repo.pending('alice', 'a'))!), isTrue);
      expect(MovementRepository.balanceOf(service.current), 0);
      expect(service.current.length, 2);
    },
  );
  test(
    'Envío ausente conserva ID, bloquea otros envíos y rechaza limpiar otra operación',
    () async {
      service.beforeWrite = true;
      var repo = repository();
      final first = PendingMovement(
        groupId: 'a',
        actorUid: 'alice',
        id: 'one',
        input: input(2050),
      );
      await expectLater(repo.submit(first), throwsA(isA<AppFailure>()));
      repo = repository();
      final pending = (await repo.pending('alice', 'a'))!;
      expect(await repo.resolve(pending), isFalse);
      await expectLater(
        repo.submit(
          PendingMovement(
            groupId: 'a',
            actorUid: 'alice',
            id: 'other',
            input: input(4000),
          ),
        ),
        throwsA(isA<AppFailure>()),
      );
      await expectLater(
        storage().clear('alice', 'a', 'other'),
        throwsA(isA<AppFailure>()),
      );
      expect((await repo.pending('alice', 'a'))?.id, 'one');
      service.beforeWrite = false;
      await expectLater(repo.submit(pending), throwsA(isA<AppFailure>()));
      repo = repository();
      expect(await repo.resolve((await repo.pending('alice', 'a'))!), isTrue);
      expect(service.current.single.id, 'one');
      expect(service.current.single.input.amountCents, 2050);
      final original = service.current.single;
      final correction = PendingMovement(
        groupId: 'a',
        actorUid: 'alice',
        id: 'correction',
        input: input(3000),
        original: original,
        reason: 'Corregir',
      );
      service.beforeWrite = true;
      await expectLater(repo.submit(correction), throwsA(isA<AppFailure>()));
      await expectLater(
        service.cancel('a', original, 'otherAdmin', 'Cambio concurrente'),
        throwsA(isA<AppFailure>()),
      );
      await expectLater(repo.resolve(correction), throwsA(isA<AppFailure>()));
      service.offlineRead = true;
      await expectLater(repo.discard(correction), throwsA(isA<AppFailure>()));
      expect((await repo.pending('alice', 'a'))?.id, 'correction');
      service.offlineRead = false;
      await repo.discard(correction);
      expect(await repo.pending('alice', 'a'), isNull);
      expect(service.current.single.status, MovementStatus.cancelled);
      expect(service.current.single.cancelledBy, 'otherAdmin');
    },
  );
  test(
    'Calendario del grupo respeta zona y horario de verano sin cambiar el día efectivo',
    () {
      final winter = TimeZoneGroupClockService(
        now: () => DateTime.utc(2026, 1, 1, 22, 30),
      );
      final summer = TimeZoneGroupClockService(
        now: () => DateTime.utc(2026, 6, 1, 22, 30),
      );
      expect(winter.today('Europe/Madrid'), DateTime.utc(2026, 1, 1));
      expect(summer.today('Europe/Madrid'), DateTime.utc(2026, 6, 2));
      expect(summer.today('America/Los_Angeles'), DateTime.utc(2026, 6, 1));
      expect(() => winter.today('zona-inventada'), throwsA(isA<AppFailure>()));
      final nextDay = MovementInput(
        type: MovementType.income,
        amountCents: 100,
        occurredAt: DateTime.utc(2026, 6, 2),
        description: '',
        personId: 'p',
      );
      expect(
        MovementRepository.inputError(
          nextDay,
          today: summer.today('Europe/Madrid'),
        ),
        isNull,
      );
      expect(
        MovementRepository.inputError(
          nextDay,
          today: summer.today('America/Los_Angeles'),
        ),
        isNotNull,
      );
    },
  );
}
