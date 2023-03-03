import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../utils/event_bus.dart';

enum DatabaseEvent {
  notification,
  insertOrReplaceMessage,
  deleteMessage,
}

class _DatabaseEventWrapper {
  _DatabaseEventWrapper(this.type, this.data);

  final DatabaseEvent type;
  final dynamic data;

  @override
  String toString() => 'DatabaseEvent{type: $type, data: $data}';
}

class DataBaseEventBus {
  const DataBaseEventBus._();

  static const DataBaseEventBus instance = DataBaseEventBus._();

  Stream<T> watch<T>(DatabaseEvent event) => EventBus.instance.on
      .whereType<_DatabaseEventWrapper>()
      .where((e) => event == e.type)
      .where((e) => e.data is T)
      .map((e) => e.data)
      .cast<T>();

  void send<T>(DatabaseEvent event, T value) =>
      EventBus.instance.fire(_DatabaseEventWrapper(event, value));
}
