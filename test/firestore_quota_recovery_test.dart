import 'package:bote_parroquial/core/errors/app_failure.dart';
import 'package:bote_parroquial/services/firestore_group_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// Test-only SDK double: inject a stream error without a platform connection.
// ignore: subtype_of_sealed_class
class _QuotaQuery extends Fake implements Query<Map<String, dynamic>> {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #where) return this;
    if (invocation.memberName == #snapshots) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.error(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'resource-exhausted',
        ),
      );
    }
    return super.noSuchMethod(invocation);
  }
}

class _Db extends Fake implements FirebaseFirestore {
  @override
  Query<Map<String, dynamic>> collectionGroup(String path) => _QuotaQuery();
}

void main() {
  test(
    'Cuota del SDK de membresías conserva la clasificación para ofrecer copias',
    () async {
      expect(
        firestoreQuotaFailure.message,
        contains('Inténtalo más tarde o mañana'),
      );
      await expectLater(
        FirestoreGroupService(_Db()).watchMemberships('alice'),
        emitsError(
          isA<AppFailure>().having(
            (e) => e.code,
            'code',
            FailureCode.resourceExhausted,
          ),
        ),
      );
    },
  );
}
