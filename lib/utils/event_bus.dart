import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'logger.dart';

const _eventBusPortName = 'mixin_global_isolate_event_bus';

enum _EventType { register, event }

@immutable
class _Event {
  const _Event({required this.data, required this.type});

  final dynamic data;
  final _EventType type;

  @override
  String toString() => '_Event{data: $data, type: $type}';
}

abstract class EventBus {
  factory EventBus._otherIsolateEventBus() {
    final port = IsolateNameServer.lookupPortByName(_eventBusPortName);
    if (port == null) {
      e('main isolate event bus not initialized. ${Isolate.current.debugName}');
      return const _DummyEventBus();
    }
    return _OtherIsolateEventBus._fromPort(port);
  }

  static EventBus? _singleton;

  static EventBus get instance =>
      _singleton ??= EventBus._otherIsolateEventBus();

  static void initialize() {
    assert(
      _singleton == null,
      'EventBus has been initialized. ${Isolate.current.debugName}',
    );
    _singleton = _MainEventBus();
  }

  Stream get on;

  void fire(dynamic event);
}

class _DummyEventBus implements EventBus {
  const _DummyEventBus();

  @override
  Stream get on => const Stream.empty();

  @override
  void fire(dynamic event) {
    e(
      'ignore dispatch event, because main event bus is not initialized.'
      ' ${Isolate.current.debugName}',
    );
  }
}

class _MainEventBus implements EventBus {
  _MainEventBus() {
    final receivePort = ReceivePort();

    if (IsolateNameServer.lookupPortByName(_eventBusPortName) != null) {
      e(
        'main isolate event bus has been initialized. '
        '(if current is hot restarted, ignore it.) ${Isolate.current.debugName}',
      );
      IsolateNameServer.removePortNameMapping(_eventBusPortName);
    }

    IsolateNameServer.registerPortWithName(
      receivePort.sendPort,
      _eventBusPortName,
    );
    receivePort.listen((event) {
      if (event is String) {
        d('remove other isolate event bus. $event');
        _ports.remove(event);
      } else if (event is _Event) {
        final type = event.type;
        switch (type) {
          case _EventType.register:
            final data = event.data as List;
            final uuid = data.first as String;
            d('register other isolate event bus. $uuid');
            final port = data[1] as SendPort;
            _ports[uuid] = port;
          case _EventType.event:
            // event from other isolate will dispatch to all other isolate.
            fire(event.data);
        }
      } else {
        assert(false, 'Invalid event type. $event');
        return;
      }
    });
  }

  final _controller = StreamController.broadcast();

  // other isolate send port. key: bus uuid.
  final Map<String, SendPort> _ports = {};

  @override
  void fire(dynamic event) {
    _controller.add(event);
    for (final port in _ports.values) {
      port.send(_Event(data: event, type: _EventType.event));
    }
  }

  @override
  Stream get on => _controller.stream;
}

class _OtherIsolateEventBus implements EventBus {
  _OtherIsolateEventBus._fromPort(this._mainBusPort) {
    final busId = const Uuid().v4();
    _mainBusPort.send(
      _Event(data: [busId, _receivePort.sendPort], type: _EventType.register),
    );
    _receivePort.listen((event) {
      if (event is! _Event) {
        assert(false, 'Invalid event type. $event');
        return;
      }
      final type = event.type;
      switch (type) {
        case _EventType.register:
          assert(false, 'Invalid event type. $event');
        case _EventType.event:
          _controller.add(event.data);
      }
    });
    Isolate.current.addOnExitListener(_mainBusPort, response: busId);
  }

  final _controller = StreamController.broadcast();

  final _receivePort = ReceivePort();

  final SendPort _mainBusPort;

  @override
  void fire(dynamic event) {
    _mainBusPort.send(_Event(data: event, type: _EventType.event));
  }

  @override
  Stream get on => _controller.stream;
}
