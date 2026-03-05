import 'dart:async';

import 'protocol.dart';
import 'router.dart';

class IsolateRpcException implements Exception {
  IsolateRpcException({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final Object? details;

  @override
  String toString() => 'IsolateRpcException($code): $message';
}

class IsolateRpcTimeoutException implements Exception {
  IsolateRpcTimeoutException(this.requestId, this.method);

  final String requestId;
  final String method;

  @override
  String toString() =>
      'IsolateRpcTimeoutException: $method($requestId) timed out';
}

class IsolateRpcClient {
  IsolateRpcClient(
    this._router, {
    this.defaultTimeout = const Duration(seconds: 10),
  }) {
    _responseSubscription = _router.rpcResponses.listen(_handleResponse);
  }

  final IsolateRouter _router;
  final Duration defaultTimeout;

  late final StreamSubscription<RpcResponse> _responseSubscription;
  int _requestSeq = 0;
  final Map<String, _PendingRequest> _pending = {};

  Future<Object?> request(
    String method, {
    Object? payload,
    Duration? timeout,
  }) {
    final requestId =
        '${DateTime.now().microsecondsSinceEpoch}_${_requestSeq++}';
    final completer = Completer<Object?>();
    final timer = Timer(timeout ?? defaultTimeout, () {
      final pending = _pending.remove(requestId);
      if (pending == null || pending.completer.isCompleted) return;
      pending.completer.completeError(
        IsolateRpcTimeoutException(requestId, method),
      );
      _router.sendRpcCancel(RpcCancelRequest(requestId: requestId));
    });

    _pending[requestId] = _PendingRequest(
      completer: completer,
      timer: timer,
    );

    _router.sendRpcRequest(
      RpcRequest(requestId: requestId, method: method, payload: payload),
    );

    return completer.future;
  }

  void cancel(String requestId) {
    final pending = _pending.remove(requestId);
    if (pending == null) return;
    pending.timer.cancel();
    if (!pending.completer.isCompleted) {
      pending.completer.completeError(
        IsolateRpcException(
          code: 'rpc_canceled',
          message: 'Request canceled by caller',
        ),
      );
    }
    _router.sendRpcCancel(RpcCancelRequest(requestId: requestId));
  }

  void _handleResponse(RpcResponse response) {
    final pending = _pending.remove(response.requestId);
    if (pending == null) return;
    pending.timer.cancel();

    if (pending.completer.isCompleted) return;

    switch (response) {
      case RpcSuccessResponse(:final result):
        pending.completer.complete(result);
      case RpcErrorResponse(:final code, :final message, :final details):
        pending.completer.completeError(
          IsolateRpcException(code: code, message: message, details: details),
        );
      case RpcCanceledResponse():
        pending.completer.completeError(
          IsolateRpcException(
            code: 'rpc_canceled',
            message: 'Request canceled by remote',
          ),
        );
    }
  }

  Future<void> dispose() async {
    await _responseSubscription.cancel();
    for (final pending in _pending.values) {
      pending.timer.cancel();
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(
          IsolateRpcException(
            code: 'rpc_disposed',
            message: 'RPC client disposed before receiving response',
          ),
        );
      }
    }
    _pending.clear();
  }
}

class _PendingRequest {
  _PendingRequest({
    required this.completer,
    required this.timer,
  });

  final Completer<Object?> completer;
  final Timer timer;
}
