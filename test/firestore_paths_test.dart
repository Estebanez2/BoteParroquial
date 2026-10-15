import 'package:bote_parroquial/core/firestore/firestore_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Los datos pertenecen explícitamente a cada grupo', () {
    expect(FirestorePaths.user('u1'), 'users/u1');
    expect(FirestorePaths.member('g1', 'u1'), 'groups/g1/members/u1');
    expect(FirestorePaths.person('g2', 'p1'), 'groups/g2/persons/p1');
    expect(FirestorePaths.movement('g2', 'm1'), 'groups/g2/movements/m1');
  });
  test('Un ID no permite introducir rutas de otro grupo', () {
    expect(() => FirestorePaths.group('g1/persons/p1'), throwsArgumentError);
    expect(() => FirestorePaths.person('g1', ''), throwsArgumentError);
    expect(() => FirestorePaths.user('..'), throwsArgumentError);
  });
}
