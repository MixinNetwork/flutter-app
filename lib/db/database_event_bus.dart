import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../utils/event_bus.dart';

enum DatabaseEvent {
  notification,
  insertOrReplaceMessage,
  deleteMessage,
  updateExpiredMessageTable,
}

@immutable
class _DatabaseEventWrapper {
  const _DatabaseEventWrapper(this.type, this.data);

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

  Stream<DatabaseEvent> watchEvent(DatabaseEvent event) => EventBus.instance.on
      .whereType<_DatabaseEventWrapper>()
      .map((e) => e.type)
      .where((e) => e == event);

  void sendEvent(DatabaseEvent event) =>
      EventBus.instance.fire(_DatabaseEventWrapper(event, null));
}
