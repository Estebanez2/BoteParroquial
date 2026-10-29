import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:crypto/crypto.dart' show sha256;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../models/daily_snapshot.dart';
import 'daily_snapshot_service.dart';

/// Encrypted, app-private, per account. Only complete authenticated files enter
/// the catalog; staging files and corrupt archives never replace a valid copy.
class FileSnapshotStorage implements SnapshotStorage {
  FileSnapshotStorage({
    Future<Directory> Function()? directory,
    Future<SecretKey> Function(String uid)? key,
  }) : _directory = directory ?? getApplicationSupportDirectory,
       _testKey = key;
  final Future<Directory> Function() _directory;
  final Future<SecretKey> Function(String uid)? _testKey;
  final _cipher = AesGcm.with256bits();
  final _secure = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );
  Future<void> _tail = Future.value();
  Future<T> _serial<T>(Future<T> Function() work) {
    final result = _tail.then((_) => work());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  String _hash(String uid) => sha256.convert(utf8.encode(uid)).toString();
  Future<Directory> _folder(String uid) async => Directory.fromUri(
    (await _directory()).absolute.uri.resolve(
      'bote_daily_copies_v1/${_hash(uid)}/',
    ),
  );
  Future<SecretKey> _key(String uid) async {
    if (_testKey != null) return _testKey(uid);
    final name = 'bote_daily_copy_key_${_hash(uid)}',
        saved = await _secure.read(key: name);
    if (saved != null) return SecretKey(base64Decode(saved));
    final key = await _cipher.newSecretKey();
    await _secure.write(
      key: name,
      value: base64Encode(await key.extractBytes()),
    );
    return key;
  }

  Future<List<File>> _files(String uid) async {
    final folder = await _folder(uid);
    if (!await folder.exists()) return [];
    final result = <File>[];
    await for (final entry in folder.list(followLinks: false)) {
      if (entry is File &&
          RegExp(r'[/\\]\d{4}-\d\d-\d\d\.snapshot$').hasMatch(entry.path)) {
        result.add(entry);
      }
    }
    result.sort((a, b) => b.path.compareTo(a.path));
    return result;
  }

  Future<DailySnapshot> _read(File file, String uid) async {
    if (await file.length() > 128 * 1024 * 1024) throw DailySnapshot.invalid;
    final text = await file.readAsString(),
        key = await (await _key(uid)).extractBytes();
    return DailySnapshot.fromJson(await _openSnapshot(text, key, uid), uid);
  }

  Future<void> _write(DailySnapshot snapshot) async {
    final key = await (await _key(snapshot.uid)).extractBytes();
    final text = await _sealSnapshot(snapshot.toJson(), key, snapshot.uid);
    final folder = await _folder(snapshot.uid);
    await folder.create(recursive: true);
    final file = File('${folder.path}/${snapshot.day}.snapshot');
    final staging = File(
      '${file.path}.${DateTime.now().microsecondsSinceEpoch}.pending',
    );
    try {
      await staging.writeAsString(text, flush: true);
      final verified = await _read(staging, snapshot.uid);
      if (jsonEncode(verified.toJson()) != jsonEncode(snapshot.toJson())) {
        throw DailySnapshot.invalid;
      }
      // One file per day. Capture is only automatic if that day has no valid copy.
      await staging.rename(file.path);
    } finally {
      if (await staging.exists()) await staging.delete();
    }
  }

  @override
  Future<List<SnapshotCatalogEntry>> list(String uid) => _serial(() async {
    final result = <SnapshotCatalogEntry>[];
    for (final file in await _files(uid)) {
      try {
        final copy = await _read(file, uid);
        result.add(
          SnapshotCatalogEntry(
            copy.day,
            copy.asOf,
            copy.groupIds.length,
            copy.documents.length,
          ),
        );
      } catch (_) {
        /* Keep unreadable files for diagnosis, never advertise them as valid. */
      }
    }
    return result;
  });
  @override
  Future<DailySnapshot> load(String uid, String day) => _serial(() async {
    if (!RegExp(r'^\d{4}-\d\d-\d\d$').hasMatch(day)) {
      throw DailySnapshot.invalid;
    }
    return _read(File('${(await _folder(uid)).path}/$day.snapshot'), uid);
  });
  @override
  Future<void> save(DailySnapshot snapshot) => _serial(() async {
    final existing = await _files(snapshot.uid);
    if (existing.any(
      (f) =>
          f.path.endsWith('/${snapshot.day}.snapshot') ||
          f.path.endsWith('\\${snapshot.day}.snapshot'),
    )) {
      throw const FileSystemException('A daily copy already exists');
    }
    await _write(snapshot);
    final valid = <File>[];
    for (final file in await _files(snapshot.uid)) {
      try {
        await _read(file, snapshot.uid);
        valid.add(file);
      } catch (_) {
        continue;
      }
    }
    for (final file in valid.skip(7)) {
      await file.delete();
    }
  });
  @override
  Future<void> clear(String uid) => _serial(() async {
    final folder = await _folder(uid);
    // Exact fixed child under the app-support directory, hashed UID only.
    final expected = (await _directory()).absolute.uri.resolve(
      'bote_daily_copies_v1/${_hash(uid)}/',
    );
    if (folder.absolute.uri != expected) throw DailySnapshot.invalid;
    if (await folder.exists()) await folder.delete(recursive: true);
    if (_testKey == null) {
      await _secure.delete(key: 'bote_daily_copy_key_${_hash(uid)}');
    }
  });
  @override
  Future<void> restrict(String uid, Map<String, String> currentAccess) =>
      _serial(() async {
        for (final file in await _files(uid)) {
          DailySnapshot copy;
          try {
            copy = await _read(file, uid);
          } catch (_) {
            continue;
          }
          final denied = <String>{};
          for (final group in copy.groupIds) {
            final rows = copy.documents.where(
              (d) => d.path == 'groups/$group/members/$uid',
            );
            if (rows.length != 1 ||
                currentAccess[group] != snapshotAccessStamp(rows.single)) {
              denied.add(group);
            }
          }
          if (denied.isEmpty) continue;
          if (denied.length == copy.groupIds.length) {
            await file.delete();
            continue;
          }
          await _write(
            DailySnapshot(
              uid: uid,
              day: copy.day,
              readTime: copy.readTime,
              savedAt: copy.savedAt,
              documents: copy.documents.where(
                (d) =>
                    !d.path.startsWith('groups/') ||
                    !denied.contains(d.path.split('/')[1]),
              ),
            ),
          );
        }
      });
}

String snapshotAccessStamp(SnapshotDocument member) => jsonEncode({
  'role': member.fields['role'],
  'personId': member.fields['personId'],
  'updatedAt': member.fields['updatedAt'],
});

// Only plain data/bytes cross the isolate boundary. Platform key access stays on
// the main isolate; JSON and AES work must not stall animations while copying.
Future<String> _sealSnapshot(
  Map<String, Object?> data,
  List<int> key,
  String uid,
) => Isolate.run(() async {
  final bytes = utf8.encode(jsonEncode(data));
  if (bytes.length > 96 * 1024 * 1024) throw DailySnapshot.invalid;
  final box = await AesGcm.with256bits().encrypt(
    bytes,
    secretKey: SecretKey(key),
    aad: utf8.encode('bote.daily-copy.v1/$uid'),
  );
  return jsonEncode({
    'version': 1,
    'nonce': base64Encode(box.nonce),
    'ciphertext': base64Encode(box.cipherText),
    'mac': base64Encode(box.mac.bytes),
  });
});
Future<Map<String, Object?>> _openSnapshot(
  String text,
  List<int> key,
  String uid,
) => Isolate.run(() async {
  final data = jsonDecode(text) as Map;
  if (data['version'] != 1) throw DailySnapshot.invalid;
  final clear = await AesGcm.with256bits().decrypt(
    SecretBox(
      base64Decode(data['ciphertext'] as String),
      nonce: base64Decode(data['nonce'] as String),
      mac: Mac(base64Decode(data['mac'] as String)),
    ),
    secretKey: SecretKey(key),
    aad: utf8.encode('bote.daily-copy.v1/$uid'),
  );
  return Map<String, Object?>.from(jsonDecode(utf8.decode(clear)) as Map);
});
