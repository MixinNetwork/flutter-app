import 'dart:async';

import '../../utils/logger.dart';
import '../../workers/isolate_event.dart';
import 'protocol.dart';

enum IsolateRouterSide { main, worker }

class IsolateRouter {
  IsolateRouter._({
    required IsolateRouterSide side,
    required Stream<dynamic> inbound,
    required void Function(Object message) sendMessage,
  }) : _side = side,
       _sendMessage = sendMessage {
    _inboundSubscription = inbound.listen(
      _handleInbound,
      onError: _errorsController.add,
    );
  }

  factory IsolateRouter.main({
    required Stream<dynamic> inbound,
    required void Function(Object message) sendMessage,
  }) => IsolateRouter._(
    side: IsolateRouterSide.main,
    inbound: inbound,
    sendMessage: sendMessage,
  );

  factory IsolateRouter.worker({
    required Stream<dynamic> inbound,
    required void Function(Object message) sendMessage,
  }) => IsolateRouter._(
    side: IsolateRouterSide.worker,
    inbound: inbound,
    sendMessage: sendMessage,
  );

  final IsolateRouterSide _side;
  final void Function(Object message) _sendMessage;
  late final StreamSubscription<dynamic> _inboundSubscription;

  final _commandsController = StreamController<WorkerCommand>.broadcast();
  final _eventsController = StreamController<WorkerEvent>.broadcast();
  final _rpcRequestsController = StreamController<RpcRequest>.broadcast();
  final _rpcResponsesController = StreamController<RpcResponse>.broadcast();
  final _rpcCancelsController = StreamController<RpcCancelRequest>.broadcast();
  final _controlsController =
      StreamController<IsolateControlMessage>.broadcast();
  final _unknownMessagesController = StreamController<dynamic>.broadcast();
  final _errorsController = StreamController<Object>.broadcast();

  Stream<WorkerCommand> get commands => _commandsController.stream;
  Stream<WorkerEvent> get events => _eventsController.stream;
  Stream<RpcRequest> get rpcRequests => _rpcRequestsController.stream;
  Stream<RpcResponse> get rpcResponses => _rpcResponsesController.stream;
  Stream<RpcCancelRequest> get rpcCancels => _rpcCancelsController.stream;
  Stream<IsolateControlMessage> get controls => _controlsController.stream;
  Stream<dynamic> get unknownMessages => _unknownMessagesController.stream;
  Stream<Object> get errors => _errorsController.stream;

  void sendCommand(WorkerCommand command) {
    _sendMessage(IsolateCommandMessage(command));
  }

  void sendEvent(WorkerEvent event) {
    _sendMessage(IsolateEventMessage(event));
  }

  void sendRpcRequest(RpcRequest request) {
    _sendMessage(IsolateRpcRequestMessage(request));
  }

  void sendRpcResponse(RpcResponse response) {
    _sendMessage(IsolateRpcResponseMessage(response));
  }

  void sendRpcCancel(RpcCancelRequest request) {
    _sendMessage(IsolateRpcCancelMessage(request));
  }

  void sendControl(IsolateControlSignal signal) {
    _sendMessage(
      IsolateControlWireMessage(
        IsolateControlMessage(
          signal: signal,
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        ),
      ),
    );
  }

  void sendReady() => sendControl(IsolateControlSignal.ready);

  void _handleInbound(dynamic message) {
    if (message is IsolateCommandMessage) {
      _commandsController.add(message.command);
      return;
    }
    if (message is IsolateEventMessage) {
      _eventsController.add(message.event);
      return;
    }
    if (message is IsolateRpcRequestMessage) {
      _rpcRequestsController.add(message.request);
      return;
    }
    if (message is IsolateRpcResponseMessage) {
      _rpcResponsesController.add(message.response);
      return;
    }
    if (message is IsolateRpcCancelMessage) {
      _rpcCancelsController.add(message.cancelRequest);
      return;
    }
    if (message is IsolateControlWireMessage) {
      final control = message.control;
      _controlsController.add(control);
      if (control.signal == IsolateControlSignal.ping) {
        sendControl(IsolateControlSignal.pong);
      }
      return;
    }

    // Compatibility bridge while legacy isolate events still exist.
    if (_side == IsolateRouterSide.worker &&
        message is IsolateEvent<MainIsolateEventType>) {
      _commandsController.add(WorkerCommand.fromLegacy(message));
      return;
    }
    if (_side == IsolateRouterSide.main &&
        message is IsolateEvent<WorkerIsolateEventType>) {
      _eventsController.add(WorkerEvent.fromLegacy(message));
      return;
    }

    _unknownMessagesController.add(message);
    w('unknown isolate message(${_side.name}): $message');
  }

  Future<void> dispose() async {
    await _inboundSubscription.cancel();
    await _commandsController.close();
    await _eventsController.close();
    await _rpcRequestsController.close();
    await _rpcResponsesController.close();
    await _rpcCancelsController.close();
    await _controlsController.close();
    await _unknownMessagesController.close();
    await _errorsController.close();
  }
}
