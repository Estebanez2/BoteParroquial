import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../models/movement_cash_totals.dart';

class FileCashCache {
  static final _generations = <String, int>{};
  int generation(String uid) => _generations[uid] ?? 0;
  Future<Directory> _folder(String uid) async => Directory(
    '${(await getTemporaryDirectory()).path}/bote_cash_cache/${sha256.convert(utf8.encode(uid))}',
  );
  Future<File> _file(String uid, String groupId, DateTime month) async => File(
    '${(await _folder(uid)).path}/${sha256.convert(utf8.encode('$groupId/${month.toIso8601String()}'))}.json',
  );
  Future<MovementCashTotals?> read(
    String uid,
    String groupId,
    DateTime month,
  ) async {
    try {
      final data =
          jsonDecode(await (await _file(uid, groupId, month)).readAsString())
              as Map<String, dynamic>;
      int cents(String key) => int.parse(data[key] as String);
      final value = MovementCashTotals(
        groupId: data['groupId'] as String,
        monthStart: DateTime.parse(data['monthStart'] as String),
        confirmedAt: DateTime.parse(data['confirmedAt'] as String),
        incomeCents: cents('income'),
        withdrawalCents: cents('withdrawal'),
        monthIncomeCents: cents('monthIncome'),
        monthWithdrawalCents: cents('monthWithdrawal'),
        cached: true,
      );
      value.validate(groupId, month);
      return value;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    String uid,
    MovementCashTotals data,
    int expectedGeneration,
  ) async {
    if (generation(uid) != expectedGeneration) return;
    try {
      final file = await _file(uid, data.groupId, data.monthStart);
      await file.parent.create(recursive: true);
      final temporary = File(
        '${file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
      );
      await temporary.writeAsString(
        jsonEncode({
          'groupId': data.groupId,
          'monthStart': data.monthStart.toIso8601String(),
          'confirmedAt': data.confirmedAt.toIso8601String(),
          'income': '${data.incomeCents}',
          'withdrawal': '${data.withdrawalCents}',
          'monthIncome': '${data.monthIncomeCents}',
          'monthWithdrawal': '${data.monthWithdrawalCents}',
        }),
        flush: true,
      );
      if (generation(uid) != expectedGeneration) {
        await temporary.delete();
        return;
      }
      await temporary.rename(file.path);
      if (generation(uid) != expectedGeneration && await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      /* A missing temporary cache must not fail a live query. */
    }
  }

  Future<void> clear(String uid) async {
    _generations[uid] = generation(uid) + 1;
    try {
      final directory = await _folder(uid);
      if (await directory.exists()) await directory.delete(recursive: true);
    } on FileSystemException {
      /* OS can evict this cache. */
    }
  }
}
