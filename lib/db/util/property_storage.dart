import 'dart:async';
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
    _loadProperties();
    EventBus.instance.on
        .where((event) => event is _PropertyChangedEvent)
        .cast<_PropertyChangedEvent>()
        .listen((event) {
          if (event.group == group) {
            _loadProperties();
          }
        });
  }

  Future<void> _loadProperties() async {
    final properties = await dao.getProperties(group);
    _data.addAll(properties);
    notifyListeners();
    await onPropertiesLoaded();
  }

  @protected
  @mustCallSuper
  Future<void> onPropertiesLoaded() async {}

  final Map<String, String> _data = {};

  final PropertyGroup group;

  final PropertyDao dao;

  void clear() {
    _data.clear();
    notifyListeners();
    dao.clearProperties(group).whenComplete(() {
      EventBus.instance.fire(_PropertyChangedEvent(group));
    });
    onPropertiesClear();
  }

  @protected
  @mustCallSuper
  Future<void> onPropertiesClear() async {}

  void remove(String key) {
    _data.remove(key);
    notifyListeners();
    dao.removeProperty(group, key).whenComplete(() {
      EventBus.instance.fire(_PropertyChangedEvent(group));
    });
  }

  void set<T>(String key, T? value) {
    if (value == null) {
      remove(key);
      return;
    }
    final String save;
    if (value is Map || value is List) {
      save = jsonEncode(value);
    } else {
      save = value is String ? value : value.toString();
    }
    _data[key] = save;
    notifyListeners();

    dao.setProperty(group, key, save).whenComplete(() {
      EventBus.instance.fire(_PropertyChangedEvent(group));
    });
  }

  T? get<T>(String key) {
    final value = _data[key];
    if (value == null) {
      return null;
    }
    try {
      if (T == String) {
        return value as T;
      } else if (T == int) {
        return int.tryParse(value) as T?;
      } else if (T == double) {
        return double.tryParse(value) as T?;
      } else if (T == bool) {
        return (value == 'true') as T?;
      } else if (T == dynamic) {
        return value as T?;
      } else {
        e('getProperty unknown type: $T');
        return null;
      }
    } catch (error, stacktrace) {
      e('getProperty error: $error, stacktrace: $stacktrace');
      return null;
    }
  }

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
}
