import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_failure.dart';
import '../core/firestore/firestore_paths.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import 'group_service.dart';

class FirestoreGroupService implements GroupService {
  const FirestoreGroupService(this._firestore);
  final FirebaseFirestore _firestore;
  static const _invalid = AppFailure(
    FailureCode.invalidData,
    'La información del grupo no tiene un formato válido.',
  );

  Stream<T> _guard<T>(Stream<T> stream) async* {
    try {
      yield* stream;
    } on FirebaseException catch (error) {
      throw switch (error.code) {
        'permission-denied' || 'unauthenticated' => const AppFailure(
          FailureCode.permissionDenied,
          'No tienes acceso a este espacio. Vuelve a tus grupos.',
        ),
        'unavailable' || 'deadline-exceeded' => const AppFailure(
          FailureCode.network,
          'No se pudo conectar. Comprueba tu conexión y reintenta.',
        ),
        'failed-precondition' => const AppFailure(
          FailureCode.configuration,
          'El acceso a grupos necesita completar su configuración.',
        ),
        _ => const AppFailure(
          FailureCode.unknown,
          'No se pudo cargar el grupo. Inténtalo de nuevo.',
        ),
      };
    }
  }

  static String _text(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.trim().isEmpty) throw _invalid;
    return value;
  }

  static DateTime _date(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! Timestamp) throw _invalid;
    return value.toDate().toUtc();
  }

  static String? _optional(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value != null && value is! String) throw _invalid;
    return value as String?;
  }

  static GroupMember _member(DocumentSnapshot<Map<String, dynamic>> doc) {
    final path = doc.reference.path.split('/');
    final data = doc.data();
    if (data == null ||
        path.length != 4 ||
        path[0] != 'groups' ||
        path[2] != 'members' ||
        data['uid'] != doc.id ||
        !['active', 'inactive'].contains(data['status'])) {
      throw _invalid;
    }
    final role = switch (data['role']) {
      'owner' => GroupRole.owner,
      'admin' => GroupRole.admin,
      'member' => GroupRole.member,
      _ => throw _invalid,
    };
    return GroupMember(
      groupId: path[1],
      uid: doc.id,
      displayName: _text(data, 'displayName'),
      role: role,
      isActive: data['status'] == 'active',
      personId: _optional(data, 'personId'),
      joinedAt: _date(data, 'joinedAt'),
      updatedAt: _date(data, 'updatedAt'),
    );
  }

  @override
  Stream<List<GroupMember>> watchMemberships(String uid) => _guard(
    _firestore
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_member).toList(growable: false)),
  );
  @override
  Stream<List<GroupMember>> watchMembers(String groupId) => _guard(
    _firestore.collection(FirestorePaths.members(groupId)).snapshots().map((
      snapshot,
    ) {
      final members = snapshot.docs.map(_member).toList();
      members.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
      return List.unmodifiable(members);
    }),
  );
  @override
  Stream<Group?> watchGroup(String groupId) => _guard(
    _firestore.doc(FirestorePaths.group(groupId)).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      if (data['isActive'] is! bool) throw _invalid;
      return Group(
        id: doc.id,
        name: _text(data, 'name'),
        description: _optional(data, 'description'),
        currency: _text(data, 'currency'),
        timeZone: _text(data, 'timeZone'),
        isActive: data['isActive'] as bool,
        createdBy: _text(data, 'createdBy'),
        createdAt: _date(data, 'createdAt'),
        updatedAt: _date(data, 'updatedAt'),
      );
    }),
  );
}
