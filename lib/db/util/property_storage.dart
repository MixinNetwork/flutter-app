import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../enum/property_group.dart';
import '../../utils/event_bus.dart';
import '../../utils/logger.dart';
import '../dao/property_dao.dart';

class _PropertyChangedEvent {
  _PropertyChangedEvent(this.group);

  final PropertyGroup group;
}

class PropertyStorage extends ChangeNotifier {
  PropertyStorage(this.group, this.dao) {
    EventBus.instance.on
        .where((event) => event is _PropertyChangedEvent)
        .cast<_PropertyChangedEvent>()
        .listen((event) {
      if (event.group == group) {
        notifyListeners();
      }
    });
  }

  final PropertyGroup group;

  final PropertyDao dao;

  Future<void> clear() async {
    await dao.clearProperties(group);
    EventBus.instance.fire(_PropertyChangedEvent(group));
  }

  Future<void> remove(String key) async {
    await dao.removeProperty(group, key);
    EventBus.instance.fire(_PropertyChangedEvent(group));
  }

  Future<void> set<T>(String key, T? value) async {
    if (value == null) {
      await remove(key);
      return;
    }
    final String save;
    if (value is Map || value is List) {
      save = jsonEncode(value);
    } else {
      save = value is String ? value : value.toString();
    }
    await dao.setProperty(group, key, save);
    EventBus.instance.fire(_PropertyChangedEvent(group));
  }

  Future<T?> get<T>(String key) async {
    final value = await dao.getProperty(group, key);
    if (value == null) {
      return null;
    }
    try {
      switch (T) {
        case String:
          return value as T?;
        case int:
          return int.tryParse(value) as T?;
        case double:
          return double.tryParse(value) as T?;
        case bool:
          return (value == 'true') as T?;
        case dynamic:
          return value as T?;
        default:
          e('getProperty unknown type: $T');
          return null;
      }
    } catch (error, stacktrace) {
      e('getProperty error: $error, stacktrace: $stacktrace');
      return null;
    }
  }

  Future<List<T>?> getList<T>(String key) async {
    final value = await dao.getProperty(group, key);
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

  Future<Map<K, V>?> getMap<K, V>(String key) async {
    final value = await dao.getProperty(group, key);
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
}
