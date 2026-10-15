// Opt-in native check, DEBUG ONLY. Restores the normal app after reporting results.
// Run with --dart-define=SMOKE_GROUP_ID=<authorized test group>.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bote_parroquial/app/app.dart';
import 'package:bote_parroquial/app/router.dart';
import 'package:bote_parroquial/core/firebase/firebase_bootstrap.dart';
import 'package:bote_parroquial/features/auth/providers/auth_providers.dart';
import 'package:bote_parroquial/models/movement.dart';
import 'package:bote_parroquial/repositories/movement_repository.dart';
import 'package:bote_parroquial/services/firestore_movement_service.dart';
import 'package:bote_parroquial/services/firestore_person_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kDebugMode) throw StateError('Solo se permite en debug.');
  final startup = await initializeFirebase();
  const groupId = String.fromEnvironment('SMOKE_GROUP_ID');
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Comprobando movimientos de prueba…')),
      ),
    ),
  );
  var passed = false;
  try {
    if (!startup.isReady || groupId.isEmpty) {
      throw StateError('Firebase o SMOKE_GROUP_ID no están preparados.');
    }
    final user = await FirebaseAuth.instance.authStateChanges().first.timeout(
      const Duration(seconds: 20),
    );
    if (user == null) {
      throw StateError('Inicia sesión primero en la app normal.');
    }
    final db = FirebaseFirestore.instance;
    final group = await db
        .doc('groups/$groupId')
        .get(const GetOptions(source: Source.server));
    if (group.data()?['createdBy'] != user.uid) {
      throw StateError(
        'La cuenta actual no es la propietaria del grupo de prueba.',
      );
    }
    final repo = MovementRepository(FirestoreMovementService(db));
    final persons = await FirestorePersonService(db)
        .watchPersons(groupId)
        .firstWhere((people) => people.any((p) => p.id == 'demo4-marta'))
        .timeout(const Duration(seconds: 20));
    const prefix = 'native4-';
    var list = await repo.loadMovements(groupId);
    final baseline = MovementRepository.balanceOf(
      list.where((m) => !m.id.startsWith(prefix)),
    );
    Movement find(String id) => list.firstWhere((m) => m.id == id);
    MovementInput input(
      int amount, {
      String? person = 'demo4-ana',
      MovementType type = MovementType.income,
    }) => MovementInput(
      type: type,
      amountCents: amount,
      occurredAt: DateTime.utc(2026, 10, 15),
      description: 'DEMO: comprobación nativa Phase 4',
      personId: person,
    );
    await repo.save(groupId, '${prefix}original', user.uid, input(2050));
    await repo.save(groupId, '${prefix}original', user.uid, input(2050));
    list = await repo.loadMovements(groupId);
    final original = find('${prefix}original');
    await repo.save(
      groupId,
      '${prefix}replacement',
      user.uid,
      input(3000),
      original: original,
      reason: 'DEMO: corrección nativa',
    );
    await repo.save(
      groupId,
      '${prefix}replacement',
      user.uid,
      input(3000),
      original: original,
      reason: 'DEMO: corrección nativa',
    );
    list = await repo.loadMovements(groupId);
    final replacement = find('${prefix}replacement');
    await repo.cancel(groupId, replacement, user.uid, 'DEMO: anulación nativa');
    await repo.cancel(groupId, replacement, user.uid, 'DEMO: anulación nativa');
    await repo.save(
      groupId,
      '${prefix}general',
      user.uid,
      input(700, person: null, type: MovementType.withdrawal),
    );
    list = await repo.loadMovements(groupId);
    await repo.cancel(
      groupId,
      find('${prefix}general'),
      user.uid,
      'DEMO: retirada de comprobación anulada',
    );
    final review = await repo.review(
      groupId,
      input(1250, person: 'demo4-marta'),
      persons,
    );
    if (!review.inactivePerson) {
      throw StateError('Falta advertencia de persona inactiva.');
    }
    await repo.save(
      groupId,
      '${prefix}inactive',
      user.uid,
      input(1250, person: 'demo4-marta'),
    );
    list = await repo.loadMovements(groupId);
    final docs = list.where((m) => m.id.startsWith(prefix)).toList();
    final balance = MovementRepository.balanceOf(list);
    if (docs.length != 4 ||
        balance != baseline + 1250 ||
        find('${prefix}original').status != MovementStatus.corrected ||
        find('${prefix}replacement').status != MovementStatus.cancelled) {
      throw StateError('Estado o saldo inesperados.');
    }
    debugPrint(
      'PHASE4_SMOKE_PASS ${jsonEncode({'groupId': groupId, 'nativeDocs': docs.length, 'baselineCents': baseline, 'balanceCents': balance, 'duplicateSubmissions': 'no duplicates'})}',
    );
    passed = true;
  } catch (error) {
    debugPrint('PHASE4_SMOKE_FAIL $error');
  }
  final container = ProviderContainer(
    overrides: [firebaseStartupProvider.overrideWithValue(startup)],
  );
  if (passed) {
    await container.read(authStateProvider.future);
    container.read(routerProvider).go('/groups/$groupId/movements');
  }
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BoteParroquialApp(),
    ),
  );
}
