import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/errors/app_failure.dart';
import '../models/movement.dart';
import '../models/pending_movement.dart';
import 'pending_movement_service.dart';

/// No SDK auth tokens or credentials are stored. Files are private to the app.
class FilePendingMovementService implements PendingMovementService {
  FilePendingMovementService({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _directory;
  Future<void> _queue = Future.value();
  Future<T> _locked<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  static const _failure = AppFailure(
    FailureCode.configuration,
    'No pudimos recuperar o guardar el envío pendiente en este móvil. No repitas la operación sin revisar el historial.',
  );
  Future<File> _file(String uid, String groupId) async {
    final root = await _directory();
    final key = base64Url.encode(utf8.encode(jsonEncode([uid, groupId])));
    final directory = Directory('${root.path}/pending_movements');
    await directory.create(recursive: true);
    return File('${directory.path}/$key.json');
  }

  Map<String, Object?> _input(MovementInput input) => {
    'type': input.type.name,
    'amountCents': input.amountCents,
    'occurredAt': DateTime.utc(
      input.occurredAt.year,
      input.occurredAt.month,
      input.occurredAt.day,
    ).toIso8601String(),
    'description': input.description.trim(),
    'personId': input.personId,
  };
  MovementInput _readInput(Map<String, dynamic> data) => MovementInput(
    type: MovementType.values.byName(data['type'] as String),
    amountCents: data['amountCents'] as int,
    occurredAt: DateTime.parse(data['occurredAt'] as String),
    description: data['description'] as String,
    personId: data['personId'] as String?,
  );
  @override
  Future<PendingMovement?> read(String uid, String groupId) =>
      _locked(() => _read(uid, groupId));
  Future<PendingMovement?> _read(String uid, String groupId) async {
    try {
      final file = await _file(uid, groupId);
      if (!await file.exists()) return null;
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (data['version'] != 1 ||
          data['uid'] != uid ||
          data['groupId'] != groupId) {
        throw _failure;
      }
      final original = data['original'] as Map<String, dynamic>?;
      return PendingMovement(
        groupId: groupId,
        actorUid: uid,
        id: data['id'] as String,
        input: _readInput(data['input'] as Map<String, dynamic>),
        reason: data['reason'] as String?,
        cancel: data['cancel'] as bool,
        original: original == null
            ? null
            : Movement(
                id: original['id'] as String,
                groupId: groupId,
                input: _readInput(original['input'] as Map<String, dynamic>),
                status: MovementStatus.active,
                createdBy: original['createdBy'] as String,
                createdAt: DateTime.parse(original['createdAt'] as String),
                updatedAt: DateTime.parse(original['updatedAt'] as String),
              ),
      );
    } catch (_) {
      throw _failure;
    }
  }

  @override
  Future<void> write(PendingMovement submission) => _locked(() async {
    try {
      final original = submission.original;
      final file = await _file(submission.actorUid, submission.groupId);
      if (await file.exists()) throw _failure;
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
        jsonEncode({
          'version': 1,
          'uid': submission.actorUid,
          'groupId': submission.groupId,
          'id': submission.id,
          'input': _input(submission.input),
          'reason': submission.reason?.trim(),
          'cancel': submission.cancel,
          'original': original == null
              ? null
              : {
                  'id': original.id,
                  'input': _input(original.input),
                  'createdBy': original.createdBy,
                  'createdAt': original.createdAt.toIso8601String(),
                  'updatedAt': original.updatedAt.toIso8601String(),
                },
        }),
        flush: true,
      );
      await temporary.rename(file.path);
    } catch (_) {
      throw _failure;
    }
  });

  @override
  Future<void> clear(String uid, String groupId, String expectedId) =>
      _locked(() async {
        try {
          final pending = await _read(uid, groupId);
          if (pending == null) return;
          if (pending.id != expectedId) throw _failure;
          final file = await _file(uid, groupId);
          if (await file.exists()) await file.delete();
        } catch (_) {
          throw _failure;
        }
      });
}
