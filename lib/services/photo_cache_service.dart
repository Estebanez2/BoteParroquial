import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../models/photo_target.dart';

class CachedPhoto {
  const CachedPhoto(this.bytes, this.version, this.checkedAt);
  final Uint8List? bytes;
  final String? version;
  final DateTime checkedAt;
  bool get isFresh =>
      DateTime.now().difference(checkedAt) < const Duration(minutes: 1);
}

/// Disposable private cache, never the source of permissions or file ownership.
class PhotoCacheService {
  PhotoCacheService({this._directory});
  PhotoCacheService.persistent() : _directory = getTemporaryDirectory;
  final Future<Directory> Function()? _directory;
  final _memory =
      <String, ({String uid, PhotoTarget target, CachedPhoto value})>{};
  final _epochs = <String, int>{};
  Future<void> _queue = Future.value();

  String _hash(String text) => sha256.convert(utf8.encode(text)).toString();
  String _key(String uid, PhotoTarget target) =>
      jsonEncode([uid, target.kind.name, target.groupId, target.id]);
  String epoch(String uid, PhotoTarget target) =>
      '${_epochs[uid] ?? 0}:${_epochs['$uid/${target.groupId}'] ?? 0}:${_epochs[_key(uid, target)] ?? 0}';
  Future<Directory> _folder(String uid) async {
    final root = await _directory!();
    return Directory('${root.path}/bote_photo_cache_v1/${_hash(uid)}');
  }

  Future<T> _io<T>(Future<T> Function() work, T fallback) {
    final task = _queue.then((_) async {
      try {
        return await work();
      } catch (_) {
        return fallback;
      }
    });
    _queue = task.then<void>((_) {});
    return task;
  }

  CachedPhoto? peek(String uid, PhotoTarget target) {
    final key = _key(uid, target);
    final row = _memory.remove(key);
    if (row != null) _memory[key] = row;
    return row?.value;
  }

  void _remember(String uid, PhotoTarget target, CachedPhoto value) {
    final key = _key(uid, target);
    _memory.remove(key);
    _memory[key] = (uid: uid, target: target, value: value);
    var size = _memory.values.fold<int>(
      0,
      (sum, row) => sum + (row.value.bytes?.length ?? 0),
    );
    while (_memory.length > 256 || size > 20 * 1024 * 1024) {
      final first = _memory.remove(_memory.keys.first);
      size -= first?.value.bytes?.length ?? 0;
    }
  }

  Future<CachedPhoto?> load(String uid, PhotoTarget target) async {
    final memory = peek(uid, target);
    if (memory != null || _directory == null) return memory;
    final expected = epoch(uid, target);
    return _io(() async {
      final file = File(
        '${(await _folder(uid)).path}/${_hash(_key(uid, target))}.json',
      );
      if (!await file.exists() || await file.length() > 720000) return null;
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final bytes = data['bytes'] == null
          ? null
          : base64Decode(data['bytes'] as String);
      if ((bytes?.length ?? 0) > 524288 || expected != epoch(uid, target)) {
        return null;
      }
      final value = CachedPhoto(
        bytes?.asUnmodifiableView(),
        data['version'] as String?,
        DateTime.parse(data['checkedAt'] as String),
      );
      _remember(uid, target, value);
      return value;
    }, null);
  }

  Future<void> put(
    String uid,
    PhotoTarget target,
    CachedPhoto value,
    String expected,
  ) async {
    if (epoch(uid, target) != expected) return;
    _remember(uid, target, value);
    if (_directory == null) return;
    await _io(() async {
      if (epoch(uid, target) != expected) return;
      final folder = await _folder(uid);
      await folder.create(recursive: true);
      final file = File('${folder.path}/${_hash(_key(uid, target))}.json');
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(
        jsonEncode({
          'bytes': value.bytes == null ? null : base64Encode(value.bytes!),
          'version': value.version,
          'checkedAt': value.checkedAt.toUtc().toIso8601String(),
          'groupId': target.groupId,
        }),
        flush: true,
      );
      if (epoch(uid, target) != expected) {
        await temp.delete();
        return;
      }
      if (await file.exists()) await file.delete();
      await temp.rename(file.path);
      final files = <({File file, FileStat stat})>[];
      await for (final entity in folder.list()) {
        if (entity is File) {
          files.add((file: entity, stat: await entity.stat()));
        }
      }
      files.sort((a, b) => a.stat.modified.compareTo(b.stat.modified));
      var total = files.fold<int>(0, (size, row) => size + row.stat.size);
      var count = files.length;
      for (final row in files) {
        if (total <= 40 * 1024 * 1024 && count <= 256) break;
        await row.file.delete();
        total -= row.stat.size;
        count--;
      }
    }, null);
  }

  void stale(String uid, PhotoTarget target) {
    final entry = peek(uid, target);
    if (entry != null) {
      _remember(
        uid,
        target,
        CachedPhoto(
          entry.bytes,
          entry.version,
          DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
    }
  }

  Iterable<PhotoTarget> memberTargets(String uid, String memberUid) => _memory
      .values
      .where(
        (row) =>
            row.uid == uid &&
            row.target.kind == PhotoKind.member &&
            row.target.id == memberUid,
      )
      .map((row) => row.target)
      .toList();
  void beginChange(String uid, PhotoTarget target) {
    final key = _key(uid, target);
    _epochs[key] = (_epochs[key] ?? 0) + 1;
  }

  Future<void> remove(String uid, PhotoTarget target) async {
    final key = _key(uid, target);
    beginChange(uid, target);
    _memory.remove(key);
    if (_directory == null) return;
    await _io(() async {
      final file = File('${(await _folder(uid)).path}/${_hash(key)}.json');
      if (await file.exists()) await file.delete();
    }, null);
  }

  Future<void> clearAccount(String uid) async {
    _epochs[uid] = (_epochs[uid] ?? 0) + 1;
    _memory.removeWhere((_, row) => row.uid == uid);
    if (_directory == null) return;
    await _io(() async {
      final folder = await _folder(uid);
      if (await folder.exists()) await folder.delete(recursive: true);
    }, null);
  }

  Future<void> clearGroup(String uid, String groupId) async {
    final scope = '$uid/$groupId';
    _epochs[scope] = (_epochs[scope] ?? 0) + 1;
    _memory.removeWhere(
      (_, row) => row.uid == uid && row.target.groupId == groupId,
    );
    if (_directory == null) return;
    await _io(() async {
      final folder = await _folder(uid);
      if (!await folder.exists()) return;
      await for (final file in folder.list()) {
        if (file is! File || !file.path.endsWith('.json')) continue;
        try {
          if ((jsonDecode(await file.readAsString()) as Map)['groupId'] ==
              groupId) {
            await file.delete();
          }
        } catch (_) {
          await file.delete();
        }
      }
    }, null);
  }
}
