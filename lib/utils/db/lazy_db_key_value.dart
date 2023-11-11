import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../enum/property_group.dart';

abstract class KeyValueDao<Group> {
  Future<String?> getByKey(Group group, String key);

  Future<Map<String, String>> getAll(Group group);

  Future<void> set(Group group, String key, String? value);

  Future<void> clear(Group group);

  Stream<Map<String, String>> watchAll(Group group);

  Stream<String?> watchByKey(Group group, String key);

  Stream<void> watchTableHasChanged(Group group);
}

T? _convertToType<T>(String? value) {
  if (value == null) {
    return null;
  }
  try {
    switch (T) {
      case String:
        return value as T;
      case int:
        return int.parse(value) as T;
      case double:
        return double.parse(value) as T;
      case bool:
        return (value == 'true') as T;
      case Map:
        throw Exception('use getMap instead');
      case List:
        throw Exception('use getList instead');
      default:
        return value as T;
    }
  } catch (error, stacktrace) {
    e('failed to convert $value to type $T : $error, $stacktrace');
    return null;
  }
}

typedef BaseLazyUserKeyValue = _BaseLazyDbKeyValue<UserPropertyGroup>;
typedef BaseLazyAppKeyValue = _BaseLazyDbKeyValue<AppPropertyGroup>;

class _BaseLazyDbKeyValue<G> with _DbKeyValueUpdate<G> {
  _BaseLazyDbKeyValue({
    required this.group,
    required this.dao,
  });

  @override
  final G group;
  @override
  final KeyValueDao<G> dao;

  Stream<T?> watch<T>(String key) =>
      dao.watchByKey(group, key).map(_convertToType);

  Future<T?> get<T>(String key) async {
    final value = await dao.getByKey(group, key);
    return _convertToType<T>(value);
  }

  Future<Map<K, V>?> getMap<K, V>(String key) async {
    final value = await dao.getByKey(group, key);
    if (value == null) {
      return null;
    }
    try {
      final map = jsonDecode(value) as Map;
      return map.cast<K, V>();
    } catch (error, stacktrace) {
      e('getMap $key error: $error, $stacktrace');
      return null;
    }
  }

  Future<List<T>?> getList<T>(String key) async {
    final value = await dao.getByKey(group, key);
    if (value == null) {
      return null;
    }
    try {
      final list = jsonDecode(value) as List;
      return list.cast<T>();
    } catch (error, stacktrace) {
      e('getList $key error: $error, $stacktrace');
      return null;
    }
  }
}

typedef BaseAppKeyValue = _BaseDbKeyValue<AppPropertyGroup>;

class _BaseDbKeyValue<G> extends ChangeNotifier with _DbKeyValueUpdate {
  _BaseDbKeyValue({required this.group, required this.dao}) {
    _loadProperties().whenComplete(_initCompleter.complete);
    _subscription = dao.watchTableHasChanged(group).listen((event) {
      _loadProperties();
    });
  }

  @override
  final G group;
  @override
  final KeyValueDao<G> dao;

  final Map<String, String> _data = {};

  final Completer<void> _initCompleter = Completer<void>();
  StreamSubscription? _subscription;

  Future<void> get initialized => _initCompleter.future;

  Future<void> _loadProperties() async {
    final properties = await dao.getAll(group);
    _data
      ..clear()
      ..addAll(properties);
    notifyListeners();
  }

  T? get<T>(String key) => _convertToType<T>(_data[key]);

  List<T>? getList<T>(String key) {
    final value = _data[key];
    if (value == null) {
      return null;
    }
    try {
      final list = jsonDecode(value) as List;
      return list.cast();
    } catch (error, stacktrace) {
      e('getProperty error: $error, stacktrace: $stacktrace');
      return null;
    }
  }

  Map<K, V>? getMap<K, V>(String key) {
    final value = _data[key];
    if (value == null) {
      return null;
    }
    try {
      final map = jsonDecode(value) as Map;
      return map.cast();
    } catch (error, stacktrace) {
      e('getProperty error: $error, stacktrace: $stacktrace');
      return null;
    }
  }

  @override
  Future<void> set<T>(String key, T? value) {
    if (value == null) {
      _data.remove(key);
    } else if (value is List || value is Map) {
      _data[key] = jsonEncode(value);
    } else {
      _data[key] = value.toString();
    }
    return super.set(key, value);
  }

  @override
  Future<void> clear() {
    _data.clear();
    return super.clear();
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }
}

mixin _DbKeyValueUpdate<G> {
  @protected
  abstract final G group;
  @protected
  abstract final KeyValueDao<G> dao;

  Future<void> set<T>(String key, T? value) async {
    if (value == null) {
      await dao.set(group, key, null);
      return;
    }
    if (value is List || value is Map) {
      await dao.set(group, key, jsonEncode(value));
    } else {
      await dao.set(group, key, value.toString());
    }
  }

  Future<void> clear() async {
    await dao.clear(group);
  }
}
