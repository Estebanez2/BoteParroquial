import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../models/movement.dart';
import '../../../models/person.dart';
import '../../../repositories/movement_repository.dart';
import '../../../services/firestore_movement_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../groups/providers/group_providers.dart';
import '../../persons/providers/person_providers.dart';

final movementRepositoryProvider = Provider<MovementRepository>(
  (ref) => MovementRepository(
    FirestoreMovementService(ref.watch(firestoreProvider)),
  ),
);
final movementsProvider = StreamProvider.autoDispose
    .family<List<Movement>, String>((ref, groupId) async* {
      final group = await ref.watch(groupProvider(groupId).future);
      if (!ref.mounted) return;
      if (group == null) {
        yield const [];
        return;
      }
      yield* ref.watch(movementRepositoryProvider).watchMovements(groupId);
    }, retry: (_, _) => null);
final canManageMovementsProvider = Provider.autoDispose.family<bool, String>(
  (ref, groupId) => ref.watch(canManagePersonsProvider(groupId)),
);
final movementHistoryProvider = Provider.autoDispose
    .family<AsyncValue<List<Movement>>, (String, String?)>((ref, key) {
      return ref
          .watch(movementsProvider(key.$1))
          .whenData(
            (movements) => key.$2 == null
                ? movements
                : movements
                      .where((movement) => movement.id == key.$2)
                      .toList(growable: false),
          );
    });
final movementControllerProvider = NotifierProvider.autoDispose
    .family<MovementController, AsyncValue<void>, String>(
      MovementController.new,
    );

class MovementController extends Notifier<AsyncValue<void>> {
  MovementController(this.groupId);
  final String groupId;
  @override
  AsyncValue<void> build() => const AsyncData(null);
  String startDraft() {
    Future.microtask(() {
      if (ref.mounted) clearError();
    });
    return ref.read(movementRepositoryProvider).newId(groupId);
  }

  String? validateReason(String? value) =>
      MovementRepository.reasonError(value);
  String? validateInput(MovementInput input) =>
      MovementRepository.inputError(input);
  void clearError() {
    if (!state.isLoading) state = const AsyncData(null);
  }

  String _actor() {
    final session = ref.read(authStateProvider);
    final user = session.isLoading || session.hasError
        ? null
        : session.asData?.value;
    if (user == null || !ref.read(canManageMovementsProvider(groupId))) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'Ya no tienes permiso para registrar movimientos en este grupo.',
      );
    }
    return user.uid;
  }

  Future<T?> _perform<T>(
    Future<T> Function(MovementRepository, String) action,
  ) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    try {
      final result = await action(
        ref.read(movementRepositoryProvider),
        _actor(),
      );
      if (ref.mounted) state = const AsyncData(null);
      return result;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return null;
    }
  }

  Future<MovementReview?> review(
    MovementInput? input, {
    Movement? original,
    bool cancel = false,
    String? reason,
    String? operationId,
  }) => _perform((repo, uid) async {
    final persons = await ref.read(personsProvider(groupId).future);
    if (!ref.mounted) {
      throw const AppFailure(FailureCode.cancelled, 'Operación cerrada.');
    }
    _actor();
    return repo.review(
      groupId,
      input,
      persons,
      original: original,
      cancel: cancel,
      reason: reason,
      operationId: operationId,
      actorUid: uid,
    );
  });
  Future<bool> save(
    String id,
    MovementInput input, {
    Movement? original,
    String? reason,
  }) async =>
      await _perform((repo, uid) async {
        await repo.save(
          groupId,
          id,
          uid,
          input,
          original: original,
          reason: reason,
        );
        return true;
      }) ??
      false;
  Future<bool> cancel(Movement movement, String reason) async =>
      await _perform((repo, uid) async {
        await repo.cancel(groupId, movement, uid, reason);
        return true;
      }) ??
      false;
}

class MovementLabels {
  const MovementLabels(this.persons, this.authors);
  final Map<String, String> persons, authors;
  String person(String? id) =>
      id == null ? 'El grupo' : persons[id] ?? 'Persona no disponible';
  String author(String uid) => authors[uid] ?? 'Usuario no disponible';
}

final movementLabelsProvider = Provider.autoDispose
    .family<MovementLabels, String>((ref, groupId) {
      final people =
          ref.watch(personsProvider(groupId)).asData?.value ?? <Person>[];
      final members = ref.watch(groupMembersProvider(groupId)).asData?.value;
      return MovementLabels(
        {for (final p in people) p.id: p.displayName},
        {
          if (members != null)
            for (final m in members) m.uid: m.displayName,
        },
      );
    });
