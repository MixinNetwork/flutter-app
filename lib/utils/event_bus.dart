import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'logger.dart';

const _eventBusPortName = 'mixin_global_isolate_event_bus';

enum _EventType {
  register,
  event,
  destroy,
}

class _Event {
  _Event({
    required this.data,
    required this.type,
  });

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
    assert(_singleton == null,
        'EventBus has been initialized. ${Isolate.current.debugName}');
    _singleton = _MainEventBus();
  }

  Stream get on;

  void fire(dynamic event);

  void destroy();
}

class _DummyEventBus implements EventBus {
  const _DummyEventBus();

  @override
  Stream get on => const Stream.empty();

  @override
  void fire(dynamic event) {
    e('ignore dispatch event, because main event bus is not initialized.'
        ' ${Isolate.current.debugName}');
  }

  @override
  void destroy() {}
}

class _MainEventBus implements EventBus {
  _MainEventBus() {
    final receivePort = ReceivePort();

    if (IsolateNameServer.lookupPortByName(_eventBusPortName) != null) {
      e(
        'main isolate event bus has been initialized. '
        '(if current is hot restarted, ignore it.) ${Isolate.current.debugName}',
      );
    }

    IsolateNameServer.registerPortWithName(
      receivePort.sendPort,
      _eventBusPortName,
    );
    receivePort.listen((event) {
      if (event is! _Event) {
        assert(false, 'Invalid event type. $event');
        return;
      }
      final type = event.type;
      switch (type) {
        case _EventType.register:
          d('register other isolate event bus.');
          final port = event.data as SendPort;
          _ports.add(port);
          break;
        case _EventType.event:
          // event from other isolate will dispatch to all other isolate.
          fire(event.data);
          break;
        case _EventType.destroy:
          d('destroy other isolate event bus.');
          _ports.remove(event.data as SendPort);
          break;
      }
    });
  }

  final _controller = StreamController.broadcast();

  // other isolate send port.
  final List<SendPort> _ports = [];

  @override
  void fire(dynamic event) {
    _controller.add(event);
    for (final port in _ports) {
      port.send(_Event(data: event, type: _EventType.event));
    }
  }

  @override
  Stream get on => _controller.stream;

  @override
  void destroy() {
    // main event bus not support destroy.
  }
}

class _OtherIsolateEventBus implements EventBus {
  _OtherIsolateEventBus._fromPort(this._mainBusPort) {
    _mainBusPort.send(_Event(
      data: _receivePort.sendPort,
      type: _EventType.register,
    ));
    _receivePort.listen((event) {
      if (event is! _Event) {
        assert(false, 'Invalid event type. $event');
        return;
      }
      final type = event.type;
      switch (type) {
        case _EventType.register:
          assert(false, 'Invalid event type. $event');
          break;
        case _EventType.event:
          _controller.add(event.data);
          break;
        case _EventType.destroy:
          _controller.close();
          break;
      }
    });
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

  @override
  void destroy() {
    _mainBusPort.send(_Event(
      data: _receivePort.sendPort,
      type: _EventType.destroy,
    ));
    _receivePort.close();
  }
}
