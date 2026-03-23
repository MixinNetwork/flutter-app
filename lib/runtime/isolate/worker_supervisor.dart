import 'dart:async';
import 'dart:isolate';

import 'package:stream_channel/isolate_channel.dart';

import '../../utils/logger.dart';
import 'protocol.dart';

typedef WorkerEntryPoint<T> = FutureOr<void> Function(T params);
typedef WorkerInitParamsFactory<T> = T Function(SendPort sendPort);

sealed class WorkerSupervisorEvent {
  const WorkerSupervisorEvent();
}

final class WorkerStartingEvent extends WorkerSupervisorEvent {
  const WorkerStartingEvent({required this.restartCount});

  final int restartCount;
}

final class WorkerStartedEvent extends WorkerSupervisorEvent {
  const WorkerStartedEvent({required this.restartCount});

  final int restartCount;
}

final class WorkerExitedEvent extends WorkerSupervisorEvent {
  const WorkerExitedEvent({required this.payload});

  final dynamic payload;
}

final class WorkerErrorEvent extends WorkerSupervisorEvent {
  const WorkerErrorEvent({required this.payload});

  final dynamic payload;
}

final class WorkerRestartScheduledEvent extends WorkerSupervisorEvent {
  const WorkerRestartScheduledEvent({
    required this.restartCount,
    required this.delay,
    this.reason,
  });

  final int restartCount;
  final Duration delay;
  final String? reason;
}

final class WorkerStoppedEvent extends WorkerSupervisorEvent {
  const WorkerStoppedEvent();
}

class WorkerSupervisor<T> {
  WorkerSupervisor({
    required this.entryPoint,
    required this.initParamsFactory,
    this.restartDelay = const Duration(seconds: 1),
    this.maxRestarts = 20,
    this.heartbeatInterval = const Duration(seconds: 5),
    this.heartbeatTimeout = const Duration(seconds: 15),
    this.debugName,
  });

  final WorkerEntryPoint<T> entryPoint;
  final WorkerInitParamsFactory<T> initParamsFactory;
  final Duration restartDelay;
  final int maxRestarts;
  final Duration heartbeatInterval;
  final Duration heartbeatTimeout;
  final String? debugName;

  final _messagesController = StreamController<dynamic>.broadcast();
  final _eventsController = StreamController<WorkerSupervisorEvent>.broadcast();

  Stream<dynamic> get messages => _messagesController.stream;
  Stream<WorkerSupervisorEvent> get events => _eventsController.stream;

  Isolate? _isolate;
  IsolateChannel<dynamic>? _channel;
  ReceivePort? _receivePort;
  ReceivePort? _exitPort;
  ReceivePort? _errorPort;

  StreamSubscription<dynamic>? _messageSubscription;
  StreamSubscription<dynamic>? _exitSubscription;
  StreamSubscription<dynamic>? _errorSubscription;

  Timer? _heartbeatTimer;
  DateTime _lastHeartbeatAt = DateTime.now();
  bool _running = false;
  bool _ready = false;
  bool _disposed = false;
  bool _starting = false;
  bool _shouldRun = false;
  int _restartCount = 0;
  Completer<void>? _readyCompleter;

  bool get isRunning => _running;
  bool get isReady => _running && _ready;

  Future<void> start() async {
    if (_disposed || _running || _starting) return;
    _shouldRun = true;
    _restartCount = 0;
    await _startWorker();
  }

  Future<void> stop() async {
    _shouldRun = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _teardownWorker();
    _eventsController.add(const WorkerStoppedEvent());
  }

  Future<void> waitUntilReady({Duration? timeout}) {
    if (_disposed) {
      return Future.error(StateError('worker supervisor already disposed'));
    }
    if (isReady) return Future.value();

    final completer = _readyCompleter ??= Completer<void>();
    final future = completer.future;
    final guardedFuture = future.then((_) {
      if (!isReady) {
        throw StateError('worker stopped before becoming ready');
      }
    });
    if (timeout == null) return guardedFuture;
    return guardedFuture.timeout(
      timeout,
      onTimeout: () => throw TimeoutException(
        'Worker did not become ready within ${timeout.inMilliseconds}ms',
      ),
    );
  }

  void send(Object message) {
    final channel = _channel;
    if (channel == null) {
      throw StateError('worker channel is null');
    }
    try {
      channel.sink.add(message);
    } catch (error, stacktrace) {
      e('worker supervisor send failed: $error, $stacktrace');
    }
  }

  Future<void> _startWorker() async {
    if (_disposed || _starting) return;
    _starting = true;
    _eventsController.add(WorkerStartingEvent(restartCount: _restartCount));
    try {
      _receivePort = ReceivePort();
      _exitPort = ReceivePort();
      _errorPort = ReceivePort();

      final isolate = await Isolate.spawn<T>(
        entryPoint,
        initParamsFactory(_receivePort!.sendPort),
        errorsAreFatal: false,
        onExit: _exitPort!.sendPort,
        onError: _errorPort!.sendPort,
        debugName: debugName,
      );
      _isolate = isolate;
      _channel = IsolateChannel<dynamic>.connectReceive(_receivePort!);
      _ready = false;
      _readyCompleter = Completer<void>();

      _messageSubscription = _channel!.stream.listen(
        (message) {
          if (message is IsolateControlWireMessage &&
              message.control.signal == IsolateControlSignal.pong) {
            _lastHeartbeatAt = DateTime.now();
          } else if (message is IsolateControlWireMessage &&
              message.control.signal == IsolateControlSignal.ready) {
            _markReady();
          }
          _messagesController.add(message);
        },
        onError: (error, stacktrace) {
          _eventsController.add(WorkerErrorEvent(payload: error));
          e('worker supervisor message stream error: $error, $stacktrace');
        },
      );

      _exitSubscription = _exitPort!.listen(_onWorkerExit);
      _errorSubscription = _errorPort!.listen(_onWorkerError);

      _running = true;
      _lastHeartbeatAt = DateTime.now();
      _startHeartbeat();
      _eventsController.add(WorkerStartedEvent(restartCount: _restartCount));
    } finally {
      _starting = false;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      if (!_running || !_shouldRun || _channel == null) return;

      send(
        IsolateControlWireMessage(
          IsolateControlMessage(
            signal: IsolateControlSignal.ping,
            timestampMs: DateTime.now().millisecondsSinceEpoch,
          ),
        ),
      );

      final elapsed = DateTime.now().difference(_lastHeartbeatAt);
      if (elapsed > heartbeatTimeout) {
        w('worker heartbeat timeout: ${elapsed.inMilliseconds}ms');
        unawaited(_restart(reason: 'heartbeat_timeout'));
      }
    });
  }

  void _onWorkerExit(dynamic payload) {
    _running = false;
    _eventsController.add(WorkerExitedEvent(payload: payload));
    if (_shouldRun) {
      unawaited(_restart(reason: 'worker_exit'));
    }
  }

  void _onWorkerError(dynamic payload) {
    _eventsController.add(WorkerErrorEvent(payload: payload));
    if (_shouldRun && _running) {
      unawaited(_restart(reason: 'worker_error'));
    }
  }

  Future<void> _restart({String? reason}) async {
    if (_disposed || !_shouldRun) return;
    if (_restartCount >= maxRestarts) {
      e('worker supervisor max restart count reached');
      _shouldRun = false;
      await stop();
      return;
    }

    _restartCount += 1;
    _eventsController.add(
      WorkerRestartScheduledEvent(
        restartCount: _restartCount,
        delay: restartDelay,
        reason: reason,
      ),
    );
    await _teardownWorker();
    if (!_shouldRun || _disposed) return;
    await Future<void>.delayed(restartDelay);
    if (!_shouldRun || _disposed) return;
    await _startWorker();
  }

  Future<void> _teardownWorker() async {
    _running = false;
    _resetReadyState();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    try {
      _isolate?.kill(priority: Isolate.immediate);
    } catch (error, stacktrace) {
      e('worker supervisor kill isolate failed: $error, $stacktrace');
    }
    _isolate = null;

    await _messageSubscription?.cancel();
    await _exitSubscription?.cancel();
    await _errorSubscription?.cancel();
    _messageSubscription = null;
    _exitSubscription = null;
    _errorSubscription = null;

    _channel = null;

    _receivePort?.close();
    _exitPort?.close();
    _errorPort?.close();
    _receivePort = null;
    _exitPort = null;
    _errorPort = null;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
    await _messagesController.close();
    await _eventsController.close();
  }

  void _markReady() {
    _ready = true;
    final completer = _readyCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void _resetReadyState() {
    _ready = false;
    final completer = _readyCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _readyCompleter = null;
  }
}
