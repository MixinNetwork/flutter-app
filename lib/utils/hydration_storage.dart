import 'dart:convert';
import 'dart:io';

abstract class KeyValueStorage {
  dynamic read(String key);

  Future<void> write(String key, dynamic value);

  Future<void> delete(String key);

  Future<void> clear();
}

class HydrationStorageRegistry {
  static late KeyValueStorage storage;
}

class HydrationStorageDirectory {
  const HydrationStorageDirectory(this.path);

  final String path;
}

class HydrationStorage implements KeyValueStorage {
  HydrationStorage._(this._directory, this._cache);

  final Directory _directory;
  final Map<String, dynamic> _cache;

  static Future<HydrationStorage> build({
    required HydrationStorageDirectory storageDirectory,
  }) async {
    final directory = Directory(storageDirectory.path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final cache = <String, dynamic>{};
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) {
        continue;
      }
      final key = entity.uri.pathSegments.last.replaceAll('.json', '');
      try {
        final content = await entity.readAsString();
        cache[key] = jsonDecode(content);
      } catch (_) {}
    }

    return HydrationStorage._(directory, cache);
  }

  @override
  dynamic read(String key) => _cache[key];

  @override
  Future<void> write(String key, dynamic value) async {
    _cache[key] = value;
    final file = File(_filePathFor(key));
    await file.writeAsString(jsonEncode(value));
  }

  @override
  Future<void> delete(String key) async {
    _cache.remove(key);
    final file = File(_filePathFor(key));
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> clear() async {
    _cache.clear();
    await for (final entity in _directory.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        await entity.delete();
      }
    }
  }

  String _filePathFor(String key) =>
      '${_directory.path}${Platform.pathSeparator}$key.json';
}

class HydratedUnsupportedError extends Error {
  HydratedUnsupportedError(this.value, {this.cause});

  final Object? value;
  final Object? cause;

  @override
  String toString() => 'HydratedUnsupportedError(value: $value, cause: $cause)';
}

class HydratedCyclicError extends Error {
  HydratedCyclicError([this.cause]);

  final Object? cause;

  @override
  String toString() => 'HydratedCyclicError(cause: $cause)';
}
