import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/image.dart';
import '../utils/proxy.dart';

const _kGlobalImageCacheKey = 'cacheimage';
const _kGlobalImageCacheMaxSizeBytes = 1024 * 1024 * 1024;
const _kDefaultImageCacheMaxAge = Duration(days: 7);
const _kCacheEntryFileExtension = '.image';

typedef ImageCacheFetcher =
    Future<http.StreamedResponse> Function(
      Uri uri,
      ProxyConfig? proxyConfig,
      Map<String, String> headers,
    );

/// Global disk cache for visual remote images.
///
/// The cache is shared by every account. A cache key includes the active proxy
/// configuration so bytes fetched through one proxy are never reused through
/// another connection.
class GlobalImageCache {
  GlobalImageCache._(
    this._directoryProvider,
    this._fetcher,
    this._maxSizeBytes,
  );

  @visibleForTesting
  factory GlobalImageCache.forTesting({
    required Directory directory,
    required ImageCacheFetcher fetcher,
    required int maxSizeBytes,
  }) => GlobalImageCache._(() async => directory, fetcher, maxSizeBytes);

  static final instance = GlobalImageCache._(
    _defaultDirectory,
    _fetchRemoteImage,
    _kGlobalImageCacheMaxSizeBytes,
  );

  final Future<Directory> Function() _directoryProvider;
  final ImageCacheFetcher _fetcher;
  final int _maxSizeBytes;
  final _entries = <String, _ImageCacheEntry>{};
  final _refreshes = <String, Future<Uint8List?>>{};

  Future<void>? _ready;
  Future<void> _operations = Future.value();
  var _lastTouched = DateTime.fromMillisecondsSinceEpoch(0);
  late Directory _directory;
  late File _indexFile;

  Stream<Uint8List> getBytes(
    String url, {
    required bool limitBytes,
    ProxyConfig? proxyConfig,
  }) async* {
    final key = _cacheKey(url, proxyConfig);
    final cached = await _read(key);
    if (cached != null) yield cached.bytes;

    if (cached != null && cached.entry.validTill.isAfter(DateTime.now())) {
      return;
    }

    try {
      final fresh = await _refresh(
        key,
        url,
        proxyConfig: proxyConfig,
        eTag: cached?.entry.eTag,
        limitBytes: limitBytes,
      );
      if (fresh != null &&
          (cached == null || !listEquals(cached.bytes, fresh))) {
        yield fresh;
      }
    } catch (error, stackTrace) {
      if (cached == null) Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<_CachedImage?> _read(String key) async {
    await _ensureReady();
    return _synchronized(() async {
      final entry = _entries[key];
      if (entry == null) return null;

      final file = _fileFor(key);
      if (!file.existsSync()) {
        _entries.remove(key);
        await _writeIndex();
        return null;
      }

      final bytes = entry.bytes?.target ?? await file.readAsBytes();
      entry
        ..length = bytes.length
        ..touched = _nextTouched()
        ..bytes = WeakReference(bytes);
      await _touch(file, entry.touched);
      return _CachedImage(bytes, entry);
    });
  }

  Future<Uint8List?> _refresh(
    String key,
    String url, {
    required ProxyConfig? proxyConfig,
    required String? eTag,
    required bool limitBytes,
  }) {
    final pending = _refreshes[key];
    if (pending != null) return pending;

    late final Future<Uint8List?> refresh;
    refresh =
        _fetchAndCache(
          key,
          url,
          proxyConfig: proxyConfig,
          eTag: eTag,
          limitBytes: limitBytes,
        ).whenComplete(() {
          if (identical(_refreshes[key], refresh)) _refreshes.remove(key);
        });
    _refreshes[key] = refresh;
    return refresh;
  }

  Future<Uint8List?> _fetchAndCache(
    String key,
    String url, {
    required ProxyConfig? proxyConfig,
    required String? eTag,
    required bool limitBytes,
  }) async {
    final headers = <String, String>{};
    if (eTag != null) headers[HttpHeaders.ifNoneMatchHeader] = eTag;
    final response = await _fetcher(
      Uri.base.resolve(url),
      proxyConfig,
      headers,
    );
    final validTill = _validTill(response.headers);
    final doesNotStore = _doesNotStore(response.headers);

    if (response.statusCode == HttpStatus.notModified) {
      await _discardResponse(response.stream);
      if (doesNotStore) {
        await _remove(key);
      } else {
        await _updateAfterNotModified(
          key,
          response.headers.containsKey(HttpHeaders.cacheControlHeader)
              ? validTill
              : null,
          response.headers,
        );
      }
      return null;
    }
    if (response.statusCode != HttpStatus.ok) {
      await _cancelResponse(response.stream);
      throw HttpException('NetworkImage HTTP ${response.statusCode}');
    }

    final bytes = await _readResponse(response, limitBytes: limitBytes);
    if (bytes.isEmpty) throw StateError('NetworkImage is an empty file: $url');

    if (doesNotStore) {
      await _remove(key);
      return bytes;
    }

    await _write(
      key,
      bytes,
      validTill: validTill,
      eTag: response.headers[HttpHeaders.etagHeader],
    );
    return bytes;
  }

  Future<void> _updateAfterNotModified(
    String key,
    DateTime? validTill,
    Map<String, String> headers,
  ) async {
    await _ensureReady();
    await _synchronized(() async {
      final entry = _entries[key];
      if (entry == null) return;
      entry
        ..validTill = validTill ?? entry.validTill
        ..touched = _nextTouched()
        ..eTag = headers[HttpHeaders.etagHeader] ?? entry.eTag;
      await _touch(_fileFor(key), entry.touched);
      await _writeIndex();
    });
  }

  Future<void> _write(
    String key,
    Uint8List bytes, {
    required DateTime validTill,
    required String? eTag,
  }) async {
    if (bytes.length > _maxSizeBytes) return;

    await _ensureReady();
    await _synchronized(() async {
      final file = _fileFor(key);
      final existing = _entries[key];
      final existingBytes = existing?.bytes?.target;
      if (existing != null &&
          existingBytes != null &&
          listEquals(existingBytes, bytes)) {
        existing
          ..validTill = validTill
          ..touched = _nextTouched()
          ..eTag = eTag
          ..bytes = WeakReference(existingBytes);
        await _touch(file, existing.touched);
        await _writeIndex();
        return;
      }

      final temporary = File('${file.path}.tmp');
      try {
        await temporary.writeAsBytes(bytes, flush: true);
        try {
          await temporary.rename(file.path);
        } on FileSystemException {
          if (file.existsSync()) await file.delete();
          await temporary.rename(file.path);
        }
      } catch (_) {
        if (temporary.existsSync()) await temporary.delete();
        rethrow;
      }

      final entry = _ImageCacheEntry(
        length: bytes.length,
        validTill: validTill,
        touched: _nextTouched(),
        eTag: eTag,
      )..bytes = WeakReference(bytes);
      _entries[key] = entry;
      await _touch(file, entry.touched);
      await _trim();
      await _writeIndex();
    });
  }

  Future<void> _remove(String key) async {
    await _ensureReady();
    await _synchronized(() async {
      final file = _fileFor(key);
      final hadEntry = _entries.remove(key) != null;
      if (file.existsSync()) await file.delete();
      if (hadEntry) await _writeIndex();
    });
  }

  Future<void> _ensureReady() => _ready ??= _initialize();

  Future<void> _initialize() async {
    _directory = await _directoryProvider();
    await _directory.create(recursive: true);
    _indexFile = File(p.join(_directory.path, 'index.json'));

    try {
      if (_indexFile.existsSync()) {
        final json = jsonDecode(await _indexFile.readAsString());
        if (json is Map<String, dynamic>) {
          for (final MapEntry(:key, :value) in json.entries) {
            if (!_isCacheKey(key) || value is! Map<String, dynamic>) continue;
            final entry = _ImageCacheEntry.fromJson(value);
            if (entry != null) {
              _entries[key] = entry;
              if (entry.touched.isAfter(_lastTouched)) {
                _lastTouched = entry.touched;
              }
            }
          }
        }
      }
    } on Object {
      _entries.clear();
    }

    var changed = false;
    final knownFiles = <String>{
      _indexFile.path,
      for (final key in _entries.keys) _fileFor(key).path,
    };
    await for (final entity in _directory.list()) {
      if (entity is File && !knownFiles.contains(entity.path)) {
        await entity.delete();
        changed = true;
      }
    }

    for (final key in _entries.keys.toList()) {
      final file = _fileFor(key);
      if (!file.existsSync()) {
        _entries.remove(key);
        changed = true;
        continue;
      }
      final entry = _entries[key]!;
      final length = await file.length();
      if (length == 0) {
        await file.delete();
        _entries.remove(key);
        changed = true;
        continue;
      }
      if (entry.length != length) {
        entry.length = length;
        changed = true;
      }
      final touched = file.lastModifiedSync();
      if (touched.isAfter(entry.touched)) {
        entry.touched = touched;
        changed = true;
      }
    }

    if (await _trim()) changed = true;
    if (changed || !_indexFile.existsSync()) await _writeIndex();
  }

  Future<bool> _trim() async {
    var changed = false;
    var size = 0;
    final entries = <MapEntry<String, _ImageCacheEntry>>[];
    for (final entry in _entries.entries.toList()) {
      final file = _fileFor(entry.key);
      if (!file.existsSync()) {
        _entries.remove(entry.key);
        changed = true;
        continue;
      }
      final length = await file.length();
      if (entry.value.length != length) {
        entry.value.length = length;
        changed = true;
      }
      size += length;
      entries.add(entry);
    }

    entries.sort((a, b) => a.value.touched.compareTo(b.value.touched));
    for (final entry in entries) {
      if (size <= _maxSizeBytes) break;
      final file = _fileFor(entry.key);
      if (file.existsSync()) await file.delete();
      _entries.remove(entry.key);
      size -= entry.value.length;
      changed = true;
    }
    return changed;
  }

  Future<void> _writeIndex() async {
    final temporary = File('${_indexFile.path}.tmp');
    final json = jsonEncode(
      _entries.map((key, entry) => MapEntry(key, entry.toJson())),
    );
    await temporary.writeAsString(json, flush: true);
    try {
      await temporary.rename(_indexFile.path);
    } on FileSystemException {
      if (_indexFile.existsSync()) await _indexFile.delete();
      await temporary.rename(_indexFile.path);
    }
  }

  File _fileFor(String key) =>
      File(p.join(_directory.path, '$key$_kCacheEntryFileExtension'));

  Future<void> _touch(File file, DateTime touched) async {
    try {
      await file.setLastModified(touched);
    } on FileSystemException {
      // Cache use must not fail if its LRU timestamp cannot be recorded.
    }
  }

  DateTime _nextTouched() {
    final now = DateTime.now();
    if (now.isAfter(_lastTouched)) return _lastTouched = now;
    return _lastTouched = _lastTouched.add(const Duration(milliseconds: 1));
  }

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final result = _operations.then((_) => action());
    _operations = result.then<void>((_) {}, onError: (_) {});
    return result;
  }
}

class _CachedImage {
  const _CachedImage(this.bytes, this.entry);

  final Uint8List bytes;
  final _ImageCacheEntry entry;
}

class _ImageCacheEntry {
  _ImageCacheEntry({
    required this.length,
    required this.validTill,
    required this.touched,
    required this.eTag,
  });

  static _ImageCacheEntry? fromJson(Map<String, dynamic> json) {
    final length = json['length'];
    final validTill = json['validTill'];
    final touched = json['touched'];
    if (length is! int || validTill is! int || touched is! int) return null;
    return _ImageCacheEntry(
      length: length,
      validTill: DateTime.fromMillisecondsSinceEpoch(validTill),
      touched: DateTime.fromMillisecondsSinceEpoch(touched),
      eTag: json['eTag'] as String?,
    );
  }

  int length;
  DateTime validTill;
  DateTime touched;
  String? eTag;
  WeakReference<Uint8List>? bytes;

  Map<String, Object?> toJson() => {
    'length': length,
    'validTill': validTill.millisecondsSinceEpoch,
    'touched': touched.millisecondsSinceEpoch,
    'eTag': eTag,
  };
}

Future<Directory> _defaultDirectory() async => Directory(
  p.join((await getTemporaryDirectory()).path, _kGlobalImageCacheKey),
);

Future<http.StreamedResponse> _fetchRemoteImage(
  Uri uri,
  ProxyConfig? proxyConfig,
  Map<String, String> headers,
) async => (await createRHttpClient(proxyConfig: proxyConfig)).send(
  http.Request('GET', uri)..headers.addAll(headers),
);

Future<Uint8List> _readResponse(
  http.StreamedResponse response, {
  required bool limitBytes,
}) async {
  final limit = limitBytes ? maxDownloadedImageBytes : null;
  if (limit != null && (response.contentLength ?? 0) > limit) {
    await _cancelResponse(response.stream);
    throw StateError('NetworkImage is too large');
  }

  final bytes = BytesBuilder(copy: false);
  final header = BytesBuilder(copy: false);
  var received = 0;
  bool? isGif;

  await for (final chunk in response.stream) {
    if (isGif == null) {
      final remaining = 6 - header.length;
      if (remaining > 0) header.add(chunk.take(remaining).toList());
      if (header.length == 6) isGif = _isGif(header.takeBytes());
    }

    received += chunk.length;
    final maximum = limit ?? (isGif == true ? maxDownloadedImageBytes : null);
    if (maximum != null && received > maximum) {
      throw StateError('NetworkImage is too large');
    }
    bytes.add(chunk);
  }

  final data = bytes.takeBytes();
  return isGif == true ? normalizeGifBytesIfNeeded(data) : data;
}

Future<void> _discardResponse(Stream<List<int>> stream) => stream.drain<void>();

Future<void> _cancelResponse(Stream<List<int>> stream) =>
    stream.listen((_) {}).cancel();

bool _doesNotStore(Map<String, String> headers) =>
    headers[HttpHeaders.cacheControlHeader]
        ?.split(',')
        .any((value) => value.trim().toLowerCase() == 'no-store') ??
    false;

DateTime _validTill(Map<String, String> headers) {
  var duration = _kDefaultImageCacheMaxAge;
  var mustRevalidate = false;
  final cacheControl = headers[HttpHeaders.cacheControlHeader];
  if (cacheControl != null) {
    for (final setting in cacheControl.split(',')) {
      final value = setting.trim().toLowerCase();
      if (value == 'no-cache' || value == 'no-store') {
        mustRevalidate = true;
      }
      if (value.startsWith('max-age=')) {
        duration = Duration(
          seconds: int.tryParse(value.substring('max-age='.length)) ?? 0,
        );
      }
    }
  }
  return DateTime.now().add(mustRevalidate ? Duration.zero : duration);
}

bool _isCacheKey(String value) => RegExp(r'^[0-9a-f]{64}$').hasMatch(value);

bool _isGif(Uint8List data) =>
    data.length >= 6 &&
    data[0] == 0x47 &&
    data[1] == 0x49 &&
    data[2] == 0x46 &&
    data[3] == 0x38 &&
    (data[4] == 0x37 || data[4] == 0x39) &&
    data[5] == 0x61;

String _cacheKey(String url, ProxyConfig? proxyConfig) => _hash(
  '$url\u0000${proxyConfig == null ? 'direct' : _hash(jsonEncode(proxyConfig.toJson()))}',
);

String _hash(String value) => sha256.convert(utf8.encode(value)).toString();
