import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/errors/app_failure.dart';
import '../models/movement_cash_totals.dart';
import 'file_cash_cache.dart';

/// Read-only REST aggregates preserve Firestore's int64 wire type. No cents are
/// converted through the mobile sum() SDK's floating-point return value.
class FirestoreCashAggregateService {
  const FirestoreCashAggregateService(this._db);
  final FirebaseFirestore _db;
  static AppFailure httpFailure(int status) => switch (status) {
    429 => firestoreQuotaFailure,
    401 || 403 => const AppFailure(
      FailureCode.permissionDenied,
      'Ya no puedes consultar este grupo.',
    ),
    400 => const AppFailure(
      FailureCode.configuration,
      'No se pudo preparar la consulta del resumen. Revisa su configuración.',
    ),
    _ => const AppFailure(
      FailureCode.network,
      'No se pudo contactar con Firebase para actualizar el saldo. Comprueba la conexión y reintenta.',
    ),
  };
  static const invalid = AppFailure(
    FailureCode.invalidData,
    'El servidor no ha devuelto un total entero y completo. Actualiza el resumen.',
  );
  static int decodeInteger(Object? value) {
    if (value is! Map || value['integerValue'] is! String) throw invalid;
    final exact = BigInt.tryParse(value['integerValue'] as String);
    if (exact == null ||
        exact.isNegative ||
        BigInt.from(exact.toInt()) != exact) {
      throw invalid;
    }
    return exact.toInt();
  }

  Future<MovementCashTotals> load(
    String groupId,
    String uid,
    DateTime monthStart, {
    DateTime? beforeExclusive,
    String? atReadTime,
    bool totalsOnly = false,
  }) async {
    final auth = FirebaseAuth.instanceFor(app: _db.app);
    if (auth.currentUser?.uid != uid) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'La sesión ha cambiado.',
      );
    }
    final token = await auth.currentUser?.getIdToken();
    if (token == null || auth.currentUser?.uid != uid) {
      throw const AppFailure(
        FailureCode.permissionDenied,
        'Inicia sesión para actualizar el resumen.',
      );
    }
    final http = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final uri = Uri.https(
        'firestore.googleapis.com',
        '/v1/projects/${_db.app.options.projectId}/databases/(default)/documents/groups/$groupId:runAggregationQuery',
      );
      Future<(int, String)> sum(
        String type, {
        bool month = false,
        String? readTime,
      }) async {
        Map<String, Object> filter(String field, String op, Object value) => {
          'fieldFilter': {
            'field': {'fieldPath': field},
            'op': op,
            'value': value,
          },
        };
        final filters = [
          filter('status', 'EQUAL', {'stringValue': 'active'}),
          filter('type', 'EQUAL', {'stringValue': type}),
          if (!month && beforeExclusive != null)
            filter('occurredAt', 'LESS_THAN', {
              'timestampValue': beforeExclusive.toIso8601String(),
            }),
          if (month) ...[
            filter('occurredAt', 'GREATER_THAN_OR_EQUAL', {
              'timestampValue': monthStart.toIso8601String(),
            }),
            filter('occurredAt', 'LESS_THAN', {
              'timestampValue': DateTime.utc(
                monthStart.year,
                monthStart.month + 1,
              ).toIso8601String(),
            }),
          ],
        ];
        final request = await http
            .postUrl(uri)
            .timeout(const Duration(seconds: 12));
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        request.headers.contentType = ContentType.json;
        request.write(
          jsonEncode({
            'structuredAggregationQuery': {
              'structuredQuery': {
                'from': [
                  {'collectionId': 'movements'},
                ],
                'where': {
                  'compositeFilter': {'op': 'AND', 'filters': filters},
                },
              },
              'aggregations': [
                {
                  'alias': 'total',
                  'sum': {
                    'field': {'fieldPath': 'amountCents'},
                  },
                },
              ],
            },
            'readTime': ?readTime,
          }),
        );
        final response = await request.close().timeout(
          const Duration(seconds: 12),
        );
        if (response.statusCode != 200) {
          await response.drain<void>();
          throw httpFailure(response.statusCode);
        }
        final bytes = <int>[];
        await for (final chunk in response.timeout(
          const Duration(seconds: 12),
        )) {
          bytes.addAll(chunk);
          if (bytes.length > 1048576) throw invalid;
        }
        final rows = jsonDecode(utf8.decode(bytes));
        if (rows is! List) throw invalid;
        final results = rows
            .whereType<Map>()
            .where((r) => r['result'] != null)
            .toList();
        if (results.length != 1) throw invalid;
        final result = results.single, time = result['readTime'];
        if (time is! String ||
            DateTime.tryParse(time) == null ||
            (readTime != null &&
                DateTime.parse(time) != DateTime.parse(readTime))) {
          throw invalid;
        }
        final values = result['result'];
        if (values is! Map || values['aggregateFields'] is! Map) throw invalid;
        return (
          decodeInteger((values['aggregateFields'] as Map)['total']),
          time,
        );
      }

      final income = await sum('income', readTime: atReadTime);
      final rest = await Future.wait([
        sum('withdrawal', readTime: income.$2),
        if (!totalsOnly) sum('income', month: true, readTime: income.$2),
        if (!totalsOnly) sum('withdrawal', month: true, readTime: income.$2),
      ]);
      if (auth.currentUser?.uid != uid) {
        throw const AppFailure(
          FailureCode.permissionDenied,
          'La sesión ha cambiado.',
        );
      }
      final result = MovementCashTotals(
        groupId: groupId,
        monthStart: monthStart,
        incomeCents: income.$1,
        withdrawalCents: rest[0].$1,
        monthIncomeCents: totalsOnly ? 0 : rest[1].$1,
        monthWithdrawalCents: totalsOnly ? 0 : rest[2].$1,
        confirmedAt: DateTime.parse(income.$2),
      );
      result.validate(groupId, monthStart);
      return result;
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure(
        FailureCode.network,
        'No se pudo confirmar la caja actual.',
      );
    } finally {
      http.close(force: true);
    }
  }

  Stream<MovementCashTotals> watch(
    String groupId,
    String uid,
    DateTime monthStart,
  ) {
    final cache = FileCashCache(), generation = FileCashCache().generation(uid);
    late final StreamController<MovementCashTotals> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subscription;
    Timer? debounce, retry;
    var stopped = false, busy = false, dirty = false, attempts = 0;
    var hasLive = false, cacheAllowed = true;
    Future<void> refresh() async {
      if (stopped) return;
      if (busy) {
        dirty = true;
        return;
      }
      busy = true;
      try {
        final result = await load(groupId, uid, monthStart);
        if (stopped) return;
        hasLive = true;
        cacheAllowed = true;
        await cache.write(uid, result, generation);
        if (!stopped) controller.add(result);
        attempts = 0;
      } on AppFailure catch (error, stack) {
        if (stopped) return;
        if (error.code == FailureCode.network) {
          final saved = await cache.read(uid, groupId, monthStart);
          if (stopped) return;
          if (saved != null) {
            controller.add(saved);
          } else {
            controller.addError(error, stack);
          }
          if (attempts++ < 4) {
            retry = Timer(Duration(seconds: attempts * 3), refresh);
          }
        } else if (error.code == FailureCode.resourceExhausted) {
          // A quota limit is neither an access revocation nor a network retry.
          cacheAllowed = false;
          if (!stopped) controller.addError(error, stack);
        } else {
          cacheAllowed = false;
          await cache.clear(uid);
          if (!stopped) controller.addError(error, stack);
        }
      } finally {
        busy = false;
        if (dirty && !stopped) {
          dirty = false;
          debounce = Timer(const Duration(milliseconds: 250), refresh);
        }
      }
    }

    controller = StreamController(
      onListen: () {
        unawaited(
          cache.read(uid, groupId, monthStart).then((value) {
            if (!stopped && !hasLive && cacheAllowed && value != null) {
              controller.add(value);
            }
          }),
        );
        subscription = _db
            .collection('groups/$groupId/movements')
            .orderBy('updatedAt', descending: true)
            .limit(1)
            .snapshots(includeMetadataChanges: true)
            .listen(
              (_) {
                retry?.cancel();
                debounce?.cancel();
                debounce = Timer(const Duration(milliseconds: 250), refresh);
              },
              onError: (Object e, StackTrace s) {
                cacheAllowed = false;
                unawaited(cache.clear(uid));
                if (!stopped) {
                  controller.addError(
                    const AppFailure(
                      FailureCode.permissionDenied,
                      'No se pudo comprobar el acceso a la caja.',
                    ),
                    s,
                  );
                }
              },
            );
      },
      onCancel: () async {
        stopped = true;
        debounce?.cancel();
        retry?.cancel();
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }
}
