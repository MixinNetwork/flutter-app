import 'dart:convert';

import 'package:mixin_logger/mixin_logger.dart';

import '../../enum/property_group.dart';

abstract class KeyValueDao<Group> {
  Future<String?> getByKey(Group group, String key);

  Future<Map<String, String>> getAll(Group group);

  Future<void> set(Group group, String key, String? value);

  Future<void> clear(Group group);

  Stream<Map<String, String>> watchAll(Group group);

  Stream<String?> watchByKey(Group group, String key);
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

typedef BaseUserKeyValue = _BaseLazyDbKeyValue<UserPropertyGroup>;
typedef BaseAppKeyValue = _BaseLazyDbKeyValue<AppPropertyGroup>;

class _BaseLazyDbKeyValue<G> {
  _BaseLazyDbKeyValue({
    required this.group,
    required this.dao,
  });

  final G group;
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

  Future<void> set<T>(String key, T? value) async {
    if (value == null) {
      await dao.set(group, key, null);
      return;
    }
    switch (T) {
      case String:
      case int:
      case double:
      case bool:
        await dao.set(group, key, value.toString());
      case Map:
      case List:
        await dao.set(group, key, jsonEncode(value));
      default:
        await dao.set(group, key, value.toString());
    }
  }

  Future<void> clear() async {
    await dao.clear(group);
  }
}
