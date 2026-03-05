import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import '../../blaze/blaze.dart';
import '../../db/database_event_bus.dart';
import '../../runtime/db_write/method.dart';
import '../../runtime/isolate/protocol.dart';
import '../../runtime/isolate/router.dart';
import '../../runtime/isolate/rpc_client.dart';
import '../../runtime/isolate/worker_supervisor.dart';
import '../../utils/file.dart';
import '../../utils/logger.dart';
import '../../workers/db_write_worker_isolate.dart';
import '../../workers/isolate_event.dart';
import '../../workers/sync_worker_isolate.dart';

const _kWorkerDbWriteRpcPrefix = 'db_write:';

typedef RuntimeAttachmentRequestHandler =
    Future<void> Function(
      AttachmentRequest request,
    );
typedef RuntimeApiErrorHandler = Future<void> Function(DioException error);
typedef RuntimeShowPinHandler = Future<void> Function(String conversationId);

class AppRuntimeSessionHost {
  AppRuntimeSessionHost({
    required this.identityNumber,
    required this.userId,
    required this.sessionId,
    required this.privateKey,
    required this.loginByPhoneNumber,
    required this.primarySessionId,
  });

  final String identityNumber;
  final String userId;
  final String sessionId;
  final String privateKey;
  final bool loginByPhoneNumber;
  final String? primarySessionId;

  RuntimeAttachmentRequestHandler? onAttachmentRequest;
  RuntimeApiErrorHandler? onApiRequestedError;
  RuntimeShowPinHandler? onShowPinMessage;

  WorkerSupervisor<SyncWorkerInitParams>? _syncWorkerSupervisor;
  IsolateRouter? _syncWorkerRouter;
  IsolateRpcClient? _syncWorkerRpcClient;

  WorkerSupervisor<DbWriteWorkerInitParams>? _dbWriteWorkerSupervisor;
  IsolateRouter? _dbWriteWorkerRouter;
  IsolateRpcClient? _dbWriteRpcClient;

  final _connectedStateBehaviorSubject = BehaviorSubject<ConnectedState>.seeded(
    ConnectedState.disconnected,
  );
  final _subscriptions = <StreamSubscription<dynamic>>[];
  bool _stopped = false;
  bool _disposed = false;

  ValueStream<ConnectedState> get connectedStateStream =>
      _connectedStateBehaviorSubject.stream;

  Future<void> start() async {
    if (_disposed) {
      throw StateError('runtime session host is already disposed');
    }
    _stopped = false;
    await _startDbWriteWorker();
    await _startSyncWorker();
  }

  Future<void> stop({bool graceful = true}) async {
    if (_stopped) return;
    _stopped = true;
    if (graceful) {
      sendSyncCommand(const ExitWorkerCommand());
      _sendCommandToDbWriteWorker(const ExitWorkerCommand());
    }

    await Future.wait(
      _subscriptions.map((subscription) => subscription.cancel()),
    );
    _subscriptions.clear();

    await _dbWriteRpcClient?.dispose();
    _dbWriteRpcClient = null;
    await _dbWriteWorkerRouter?.dispose();
    _dbWriteWorkerRouter = null;
    await _dbWriteWorkerSupervisor?.stop();
    await _dbWriteWorkerSupervisor?.dispose();
    _dbWriteWorkerSupervisor = null;

    await _syncWorkerRpcClient?.dispose();
    _syncWorkerRpcClient = null;
    await _syncWorkerRouter?.dispose();
    _syncWorkerRouter = null;
    await _syncWorkerSupervisor?.stop();
    await _syncWorkerSupervisor?.dispose();
    _syncWorkerSupervisor = null;

    _connectedStateBehaviorSubject.add(ConnectedState.disconnected);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
    await _connectedStateBehaviorSubject.close();
  }

  void sendSyncCommand(WorkerCommand command) {
    try {
      final router = _syncWorkerRouter;
      if (router == null) {
        d('sendSyncCommand dropped because router is null: $command');
        assert(command is ExitWorkerCommand);
        return;
      }
      router.sendCommand(command);
    } catch (error, stackTrace) {
      e('sendSyncCommand failed: $error, $stackTrace');
    }
  }

  Future<void> requestDbWrite(
    DbWriteMethod method, {
    Object? payload,
  }) async {
    final rpcClient = _dbWriteRpcClient;
    if (rpcClient == null) {
      throw StateError('db write rpc client not ready: ${method.name}');
    }

    await rpcClient.request(
      method.name,
      payload: payload,
      timeout: const Duration(seconds: 20),
    );
  }

  Future<void> _startSyncWorker() async {
    await _syncWorkerSupervisor?.dispose();
    _syncWorkerSupervisor = WorkerSupervisor<SyncWorkerInitParams>(
      entryPoint: startSyncWorkerIsolate,
      initParamsFactory: (sendPort) => SyncWorkerInitParams(
        sendPort: sendPort,
        identityNumber: identityNumber,
        userId: userId,
        sessionId: sessionId,
        privateKey: privateKey,
        mixinDocumentDirectory: mixinDocumentsDirectory.path,
        primarySessionId: primarySessionId,
        loginByPhoneNumber: loginByPhoneNumber,
        rootIsolateToken: ServicesBinding.rootIsolateToken!,
      ),
      debugName: 'mixin_sync_worker_supervisor',
    );

    _syncWorkerRouter = IsolateRouter.main(
      inbound: _syncWorkerSupervisor!.messages,
      sendMessage: _syncWorkerSupervisor!.send,
    );
    await _syncWorkerRpcClient?.dispose();
    _syncWorkerRpcClient = IsolateRpcClient(_syncWorkerRouter!);

    _subscriptions
      ..add(
        _syncWorkerSupervisor!.events.listen((event) {
          switch (event) {
            case WorkerExitedEvent(:final payload):
              w('sync worker exited. $payload');
              _connectedStateBehaviorSubject.add(ConnectedState.disconnected);
            case WorkerErrorEvent(:final payload):
              e('sync worker isolate remote error: $payload');
            case WorkerRestartScheduledEvent(:final reason, :final delay):
              w(
                'sync worker restart scheduled: $reason after ${delay.inMilliseconds}ms',
              );
            case WorkerStartingEvent():
            case WorkerStartedEvent():
            case WorkerStoppedEvent():
              break;
          }
        }),
      )
      ..add(
        _syncWorkerRouter!.events.listen((event) {
          try {
            _handleSyncWorkerEvent(event);
          } catch (error, stackTrace) {
            e('handle sync worker event failed: $error, $stackTrace');
          }
        }),
      )
      ..add(
        _syncWorkerRouter!.rpcRequests.listen((request) async {
          final router = _syncWorkerRouter;
          if (router == null) return;

          final method = request.method;
          if (!method.startsWith(_kWorkerDbWriteRpcPrefix)) {
            router.sendRpcResponse(
              RpcErrorResponse(
                requestId: request.requestId,
                code: 'unsupported_worker_rpc',
                message: 'Unsupported worker rpc method: $method',
              ),
            );
            return;
          }

          final dbWriteMethodName = method.substring(
            _kWorkerDbWriteRpcPrefix.length,
          );
          try {
            final dbRpcClient = _dbWriteRpcClient;
            if (dbRpcClient == null) {
              throw StateError('db write rpc client not ready');
            }
            final result = await dbRpcClient.request(
              dbWriteMethodName,
              payload: request.payload,
              timeout: const Duration(seconds: 20),
            );
            router.sendRpcResponse(
              RpcSuccessResponse(
                requestId: request.requestId,
                result: result,
              ),
            );
          } catch (error, stackTrace) {
            e(
              'sync worker -> db write rpc forwarding failed: method=$dbWriteMethodName '
              'error=$error, $stackTrace',
            );
            router.sendRpcResponse(
              RpcErrorResponse(
                requestId: request.requestId,
                code: 'db_write_forward_failed',
                message: error.toString(),
              ),
            );
          }
        }),
      );

    await _syncWorkerSupervisor!.start();
  }

  Future<void> _startDbWriteWorker() async {
    await _dbWriteWorkerSupervisor?.dispose();
    _dbWriteWorkerSupervisor = WorkerSupervisor<DbWriteWorkerInitParams>(
      entryPoint: startDbWriteWorkerIsolate,
      initParamsFactory: (sendPort) => DbWriteWorkerInitParams(
        sendPort: sendPort,
        identityNumber: identityNumber,
      ),
      debugName: 'mixin_db_write_worker_supervisor',
    );

    _dbWriteWorkerRouter = IsolateRouter.main(
      inbound: _dbWriteWorkerSupervisor!.messages,
      sendMessage: _dbWriteWorkerSupervisor!.send,
    );
    await _dbWriteRpcClient?.dispose();
    _dbWriteRpcClient = IsolateRpcClient(_dbWriteWorkerRouter!);

    _subscriptions
      ..add(
        _dbWriteWorkerSupervisor!.events.listen((event) {
          switch (event) {
            case WorkerExitedEvent(:final payload):
              w('db write worker exited. $payload');
            case WorkerErrorEvent(:final payload):
              e('db write worker error: $payload');
            case WorkerRestartScheduledEvent(:final reason, :final delay):
              w(
                'db write worker restart scheduled: $reason after ${delay.inMilliseconds}ms',
              );
            case WorkerStartingEvent():
            case WorkerStartedEvent():
            case WorkerStoppedEvent():
              break;
          }
        }),
      )
      ..add(
        _dbWriteWorkerRouter!.events.listen((event) {
          try {
            _handleDbWriteWorkerEvent(event);
          } catch (error, stackTrace) {
            e('handle db write isolate event failed: $error, $stackTrace');
          }
        }),
      );
    await _dbWriteWorkerSupervisor!.start();
  }

  void _handleSyncWorkerEvent(WorkerEvent event) {
    switch (event) {
      case WorkerIsolateReadyEvent():
        d('sync worker ready');
      case WorkerBlazeConnectStateChangedEvent(:final state):
        _connectedStateBehaviorSubject.add(state);
      case WorkerApiRequestedErrorEvent(:final error):
        final handler = onApiRequestedError;
        if (handler != null) {
          unawaited(handler(error));
        }
      case WorkerRequestDownloadAttachmentEvent(:final request):
        final handler = onAttachmentRequest;
        if (handler != null) {
          unawaited(handler(request));
        }
      case WorkerShowPinMessageEvent(:final conversationId):
        final handler = onShowPinMessage;
        if (handler != null) {
          unawaited(handler(conversationId));
        }
      case WorkerSyncPatchesEvent(:final patches):
        DataBaseEventBus.instance.applyPatches(patches);
    }
  }

  void _handleDbWriteWorkerEvent(WorkerEvent event) {
    switch (event) {
      case WorkerSyncPatchesEvent(:final patches):
        DataBaseEventBus.instance.applyPatches(patches);
      case WorkerIsolateReadyEvent():
      case WorkerBlazeConnectStateChangedEvent():
      case WorkerApiRequestedErrorEvent():
      case WorkerRequestDownloadAttachmentEvent():
      case WorkerShowPinMessageEvent():
        break;
    }
  }

  void _sendCommandToDbWriteWorker(WorkerCommand command) {
    try {
      final router = _dbWriteWorkerRouter;
      if (router == null) {
        d(
          'sendCommandToDbWriteWorker dropped because router is null: $command',
        );
        assert(command is ExitWorkerCommand);
        return;
      }
      router.sendCommand(command);
    } catch (error, stackTrace) {
      e('sendCommandToDbWriteWorker failed: $error, $stackTrace');
    }
  }
}
