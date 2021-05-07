import 'dart:async';

import 'package:tuple/tuple.dart';

enum DatabaseEvent {
  insert,
  insertOrReplaceMessage,
}

class DataBaseEventBus {
  final _streamController =
      StreamController<Tuple2<DatabaseEvent, dynamic>>.broadcast();

  Stream<T> watch<T>(DatabaseEvent event, {bool nullable = false}) =>
      _streamController.stream
          .where((e) => event == e.item1)
          .where((e) => nullable || e.item2 != null)
          .where((e) => e.item2 is T)
          .map((e) => e.item2);

  void send<T>(DatabaseEvent event, T value) =>
      _streamController.add(Tuple2(event, value));

  Future dispose() => _streamController.close();
}
