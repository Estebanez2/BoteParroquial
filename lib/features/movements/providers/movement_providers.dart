import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../models/movement.dart';
import '../../../models/person.dart';
import '../../../models/movement_day.dart';
import '../../../models/movement_history_filter.dart';
import '../../../repositories/movement_history_repository.dart';
import '../../../models/pending_movement.dart';
import '../../../repositories/movement_repository.dart';
import '../../../repositories/movement_submission_repository.dart';
import '../../../services/firestore_movement_service.dart';
import '../../../services/file_pending_movement_service.dart';
import '../../../services/pending_movement_service.dart';
import '../../../services/group_clock_service.dart';
import '../../../repositories/group_calendar_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../groups/providers/group_providers.dart';
import '../../persons/providers/person_providers.dart';

final movementRepositoryProvider = Provider<MovementRepository>((ref) {
  final repository = MovementRepository(
    FirestoreMovementService(ref.watch(firestoreProvider)),
  );
  var uid = ref.read(authStateProvider).asData?.value?.uid;
  ref.listen(authStateProvider, (_, next) {
    if (next.isLoading) return;
    final current = next.asData?.value?.uid;
    if (uid != null && uid != current) {
      unawaited(repository.clearCashAccount(uid!));
    }
    uid = current;
  });
  return repository;
});
final groupCalendarRepositoryProvider = Provider<GroupCalendarRepository>(
  (ref) => GroupCalendarRepository(TimeZoneGroupClockService()),
);
final pendingMovementServiceProvider = Provider<PendingMovementService>(
  (ref) => FilePendingMovementService(),
);
final movementSubmissionRepositoryProvider =
    Provider<MovementSubmissionRepository>(
      (ref) => MovementSubmissionRepository(
        ref.watch(pendingMovementServiceProvider),
        ref.watch(movementRepositoryProvider),
      ),
    );
final pendingMovementProvider = FutureProvider.autoDispose
    .family<PendingMovement?, String>((ref, groupId) async {
      final session = ref.watch(authStateProvider);
      final user = session.isLoading || session.hasError
          ? null
          : session.asData?.value;
      if (user == null ||
          ref.watch(currentMembershipProvider(groupId)) == null) {
        return null;
      }
      final repository = ref.watch(movementSubmissionRepositoryProvider);
      final submission = await repository.pending(user.uid, groupId);
      if (submission == null) return null;
      try {
        if (await repository.resolve(submission)) return null;
      } on AppFailure {
        // Keep the intention visible when the server result is still unknown.
      }
      return submission;
    }, retry: (_, _) => null);
final movementsProvider = StreamProvider.autoDispose
    .family<List<Movement>, String>((ref, groupId) {
      final group = ref.watch(groupProvider(groupId));
      if (group.isLoading) return const Stream.empty();
      if (group.hasError) return Stream.error(group.error!, group.stackTrace);
      if (group.asData?.value == null) return Stream.value(const []);
      return ref.watch(movementRepositoryProvider).watchMovements(groupId);
    }, retry: (_, _) => null);
final canManageMovementsProvider = Provider.autoDispose.family<bool, String>(
  (ref, groupId) => ref.watch(canManagePersonsProvider(groupId)),
);
final quotaSourceMovementsProvider = StreamProvider.autoDispose
    .family<List<Movement>, String>((ref, id) {
      final group = ref.watch(groupProvider(id));
      if (group.isLoading) return const Stream.empty();
      if (group.hasError) return Stream.error(group.error!, group.stackTrace);
      if (group.asData?.value == null) return Stream.value(const []);
      return ref.watch(movementRepositoryProvider).watchQuotaSources(id);
    }, retry: (_, _) => null);
final movementHistoryRepositoryProvider = Provider<MovementHistoryRepository>(
  (ref) => const MovementHistoryRepository(),
);
final movementFilterProvider = NotifierProvider.autoDispose
    .family<MovementFilterController, MovementHistoryFilter, String>(
      MovementFilterController.new,
    );

class MovementFilterController extends Notifier<MovementHistoryFilter> {
  MovementFilterController(this.groupId);
  final String groupId;
  late MovementHistoryRepository _repository;

  @override
  MovementHistoryFilter build() {
    _repository = ref.watch(movementHistoryRepositoryProvider);
    ref.watch(
      authStateProvider.select((session) => session.asData?.value?.uid),
    );
    ref.watch(
      currentMembershipProvider(groupId).select((member) => member != null),
    );
    return const MovementHistoryFilter();
  }

  void search(String query) => state = state.copyWith(query: query);
  String? validate(MovementHistoryFilter filter) =>
      _repository.filterError(filter);
  void apply(MovementHistoryFilter filter) {
    final error = validate(filter);
    if (error != null) throw AppFailure(FailureCode.invalidData, error);
    state = filter;
  }

  void reset() => state = const MovementHistoryFilter();
}

final movementHistoryOptionsProvider = Provider.autoDispose
    .family<MovementHistoryOptions, String>((ref, groupId) {
      final labels = ref.watch(movementLabelsProvider(groupId));
      final movements =
          ref.watch(movementsProvider(groupId)).asData?.value ?? <Movement>[];
      return ref
          .watch(movementHistoryRepositoryProvider)
          .options(
            groupId,
            movements,
            persons: labels.persons,
            authors: labels.authors,
          );
    });

final movementHistoryProvider = Provider.autoDispose
    .family<AsyncValue<List<Movement>>, (String, String?)>((ref, key) {
      final filter = ref.watch(movementFilterProvider(key.$1));
      final labels = ref.watch(movementLabelsProvider(key.$1));
      final repository = ref.watch(movementHistoryRepositoryProvider);
      return ref
          .watch(movementsProvider(key.$1))
          .whenData(
            (movements) => key.$2 == null
                ? repository.filter(
                    key.$1,
                    movements,
                    filter,
                    persons: labels.persons,
                    authors: labels.authors,
                  )
                : movements
                      .where((movement) => movement.id == key.$2)
                      .toList(growable: false),
          );
    });
final movementControllerProvider = NotifierProvider.autoDispose
    .family<MovementController, AsyncValue<void>, String>(
      MovementController.new,
    );
final movementDaysProvider = Provider.autoDispose
    .family<AsyncValue<List<MovementDay>>, (String, String?)>(
      (ref, key) => ref
          .watch(movementHistoryProvider(key))
          .whenData(
            (rows) =>
                const MovementHistoryRepository().groupByDay(key.$1, rows),
          ),
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
      MovementRepository.inputError(input, today: today());
  DateTime today() {
    final group = ref.read(groupProvider(groupId)).asData?.value;
    if (group == null) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'No se puede comprobar la fecha sin acceso al grupo.',
      );
    }
    return ref.read(groupCalendarRepositoryProvider).today(group.timeZone);
  }

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

  String currentActor() => _actor();

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
    if (_actor() != uid) {
      throw const AppFailure(
        FailureCode.cancelled,
        'La sesión ha cambiado. Revisa la operación desde tu cuenta actual.',
      );
    }
    return repo.review(
      groupId,
      input,
      persons,
      original: original,
      cancel: cancel,
      reason: reason,
      operationId: operationId,
      actorUid: uid,
      today: today(),
    );
  });
  Future<bool> save(
    String id,
    MovementInput input, {
    Movement? original,
    String? reason,
    String? expectedActorUid,
  }) async =>
      await _perform((repo, uid) async {
        if (expectedActorUid != null && uid != expectedActorUid) {
          throw const AppFailure(
            FailureCode.cancelled,
            'La sesión ha cambiado; revisa la operación desde tu cuenta actual.',
          );
        }
        await _submit(
          PendingMovement(
            groupId: groupId,
            id: id,
            actorUid: uid,
            input: input,
            original: original,
            reason: reason,
          ),
        );
        return true;
      }) ??
      false;
  Future<bool> cancel(
    Movement movement,
    String reason, {
    String? expectedActorUid,
  }) async =>
      await _perform((repo, uid) async {
        if (expectedActorUid != null && uid != expectedActorUid) {
          throw const AppFailure(
            FailureCode.cancelled,
            'La sesión ha cambiado. Revisa la operación desde tu cuenta actual.',
          );
        }
        await _submit(
          PendingMovement(
            groupId: groupId,
            id: movement.id,
            actorUid: uid,
            input: movement.input,
            original: movement,
            reason: reason,
            cancel: true,
          ),
        );
        return true;
      }) ??
      false;

  Future<void> _submit(PendingMovement submission) async {
    final repository = ref.read(movementSubmissionRepositoryProvider);
    try {
      await repository.submit(submission, today: today());
    } finally {
      if (ref.mounted) ref.invalidate(pendingMovementProvider(groupId));
    }
  }

  Future<bool?> checkPending(PendingMovement submission) =>
      _perform((repo, uid) async {
        if (submission.actorUid != uid || submission.groupId != groupId) {
          throw const AppFailure(
            FailureCode.permissionDenied,
            'Este envío pertenece a otra sesión.',
          );
        }
        final repository = ref.read(movementSubmissionRepositoryProvider);
        final resolved = await repository.resolve(submission);
        if (resolved && ref.mounted) {
          ref.invalidate(pendingMovementProvider(groupId));
        }
        return resolved;
      });

  Future<bool> discardPending(PendingMovement submission) async =>
      await _perform((repo, uid) async {
        if (submission.actorUid != uid || submission.groupId != groupId) {
          throw const AppFailure(
            FailureCode.permissionDenied,
            'Este envío pertenece a otra sesión.',
          );
        }
        final repository = ref.read(movementSubmissionRepositoryProvider);
        await repository.discard(submission);
        if (ref.mounted) ref.invalidate(pendingMovementProvider(groupId));
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
