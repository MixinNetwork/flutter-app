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

typedef BaseLazyUserKeyValue = _BaseLazyDbKeyValue<UserPropertyGroup>;
typedef BaseLazyAppKeyValue = _BaseLazyDbKeyValue<AppPropertyGroup>;

class _BaseLazyDbKeyValue<G> {
  _BaseLazyDbKeyValue({
    required this.group,
    required this.dao,
  });

  final G group;
  final KeyValueDao<G> dao;

  Stream<T?> watch<T>(String key) =>
      dao.watchByKey(group, key).map(convertToType);

  Future<T?> get<T>(String key) async {
    final value = await dao.getByKey(group, key);
    return convertToType<T>(value);
  }

  Future<void> set<T>(String key, T? value) =>
      dao.set(group, key, convertToString(value));

  Future<void> clear() {
    i('clear key value: $group');
    return dao.clear(group);
  }
}

typedef AppKeyValue = _BaseDbKeyValue<AppPropertyGroup>;

class _BaseDbKeyValue<G> extends ChangeNotifier {
  _BaseDbKeyValue({required this.group, required KeyValueDao<G> dao})
      : _dao = dao {
    _loadProperties().whenComplete(_initCompleter.complete);
    _subscription = dao.watchTableHasChanged(group).listen((event) {
      _loadProperties();
    });
  }

  @protected
  final G group;
  final KeyValueDao<G> _dao;

  final Map<String, String> _data = {};

  final Completer<void> _initCompleter = Completer<void>();
  StreamSubscription? _subscription;

  Future<void> get initialized => _initCompleter.future;

  Future<void> _loadProperties() async {
    final properties = await _dao.getAll(group);
    _data
      ..clear()
      ..addAll(properties);
    notifyListeners();
  }

  T? get<T>(String key) => convertToType<T>(_data[key]);

  Future<void> set<T>(String key, T? value) {
    final converted = convertToString(value);
    if (converted != null) {
      _data[key] = converted;
    } else {
      _data.remove(key);
    }
    return _dao.set(group, key, converted);
  }

  Future<void> clear() {
    i('clear key value: $group');
    _data.clear();
    return _dao.clear(group);
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }
}

@visibleForTesting
T? convertToType<T>(String? value) {
  if (value == null) {
    return null;
  }
  try {
    switch (T) {
      case const (String):
        return value as T;
      case const (int):
        return int.parse(value) as T;
      case const (double):
        return double.parse(value) as T;
      case const (bool):
        return (value == 'true') as T;
      case const (Map):
      case const (Map<String, dynamic>):
      case const (List):
        return jsonDecode(value) as T;
      case const (List<Map>):
        return (jsonDecode(value) as List).cast<Map>() as T;
      case const (List<Map<String, dynamic>>):
        return (jsonDecode(value) as List).cast<Map<String, dynamic>>() as T;
      case const (dynamic):
        return value as T;
      default:
        throw UnsupportedError('unsupported type $T');
    }
  } catch (error, stacktrace) {
    e('failed to convert $value to type $T : $error\n$stacktrace');
    return null;
  }
}

@visibleForTesting
String? convertToString(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  return jsonEncode(value);
}
