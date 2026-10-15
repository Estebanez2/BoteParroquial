import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';

abstract interface class GroupSyncService {
  Stream<bool> watchServerConfirmation(String groupId, String uid);
}

class FirestoreGroupSyncService implements GroupSyncService {
  const FirestoreGroupSyncService(this._firestore);
  final FirebaseFirestore _firestore;
  @override
  Stream<bool> watchServerConfirmation(String groupId, String uid) {
    final sources = [
      _firestore
          .doc(FirestorePaths.group(groupId))
          .snapshots(includeMetadataChanges: true)
          .map((s) => !s.metadata.isFromCache),
      _firestore
          .doc('${FirestorePaths.members(groupId)}/$uid')
          .snapshots(includeMetadataChanges: true)
          .map((s) => !s.metadata.isFromCache),
      for (final path in [
        FirestorePaths.persons(groupId),
        FirestorePaths.movements(groupId),
        FirestorePaths.members(groupId),
      ])
        _firestore
            .collection(path)
            .snapshots(includeMetadataChanges: true)
            .map(
              (s) => !s.metadata.isFromCache && !s.metadata.hasPendingWrites,
            ),
    ];
    final confirmed = List.filled(sources.length, false);
    final subscriptions = <StreamSubscription<bool>>[];
    late final StreamController<bool> controller;
    controller = StreamController<bool>(
      onListen: () {
        controller.add(false);
        for (var i = 0; i < sources.length; i++) {
          final index = i;
          subscriptions.add(
            sources[i].listen(
              (value) {
                confirmed[index] = value;
                controller.add(confirmed.every((v) => v));
              },
              onError: (Object error, StackTrace stack) {
                confirmed[index] = false;
                controller.add(false);
                controller.addError(
                  const AppFailure(
                    FailureCode.network,
                    'No se ha podido confirmar la actualización de estos datos.',
                  ),
                  stack,
                );
              },
            ),
          );
        }
      },
      onCancel: () async {
        await Future.wait(subscriptions.map((s) => s.cancel()));
      },
    );
    return controller.stream.distinct();
  }
}
