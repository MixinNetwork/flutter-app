import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart' hide Key;
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/io.dart';

import '../constants/constants.dart';
import '../db/database.dart';
import '../db/extension/job.dart';
import '../db/mixin_database.dart';
import '../utils/extension/extension.dart';
import '../utils/logger.dart';
import '../utils/proxy.dart';
import '../workers/job/ack_job.dart';
import '../workers/job/flood_job.dart';
import '../workers/message_worker_isolate.dart';
import 'blaze_message.dart';
import 'blaze_message_param_session.dart';

const String _wsHost1 = 'wss://blaze.mixin.one:443';
const String _wsHost2 = 'wss://mixin-blaze.zeromesh.net:443';
const int _fixedReconnectDelaySeconds = 5;

// --- Connection Events ---
enum _ConnectionEvent {
  connect, // Connection request (including initial connection and reconnection)
  disconnect, // Disconnect request
  error, // All error situations (including ping timeout, network errors, etc.)
  retry, // Internal event for timer-triggered retry
}

enum ConnectedState {
  connecting,
  reconnecting,
  connected,
  disconnecting,
  disconnected,
  hasLocalTimeError,
}

class Blaze {
  Blaze(
    this.userId,
    this.sessionId,
    this.privateKey,
    this.database,
    this.client,
    this.userAgent,
    this.ackJob,
    this.floodJob,
  ) {
    database.settingProperties.addListener(_onProxySettingChanged);
    proxyConfig = database.settingProperties.activatedProxy;

    // Initialize event stream handler
    _eventStreamSubscription = _eventController.stream.listen(
      _handleConnectionEvent,
    );
  }

  final String userId;
  final String sessionId;
  final String privateKey;
  final Database database;
  final Client client;
  final AckJob ackJob;
  final FloodJob floodJob;

  final String? userAgent;

  ProxyConfig? proxyConfig;

  String _host = _wsHost1;
  String? _token;

  final BehaviorSubject<ConnectedState> _connectedStateBehaviorSubject =
      BehaviorSubject<ConnectedState>();

  ValueStream<ConnectedState> get connectedStateStream =>
      _connectedStateBehaviorSubject.stream;

  IOWebSocketChannel? channel;
  StreamSubscription? subscription;

  final transactions = <String, WebSocketTransaction>{};

  ConnectedState get _connectedState =>
      _connectedStateBehaviorSubject.valueOrNull ?? ConnectedState.disconnected;

  set _connectedState(ConnectedState state) {
    if (_connectedStateBehaviorSubject.valueOrNull == state) return;
    i(
      '[State Transition] ${_connectedStateBehaviorSubject.valueOrNull} -> $state',
    );
    _connectedStateBehaviorSubject.add(state);

    if (state == ConnectedState.connected) {
      _refreshOffset();
    }

    // Cancel retry timer if we are in a state that doesn't need retry
    if (state == ConnectedState.connected ||
        state == ConnectedState.disconnected ||
        state == ConnectedState.disconnecting) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
    }
  }

  Timer? _checkTimeoutTimer;
  Timer? _reconnectTimer;

  // --- Event Stream ---
  final StreamController<_ConnectionEvent> _eventController =
      StreamController.broadcast();
  late StreamSubscription<_ConnectionEvent> _eventStreamSubscription;

  // ==========================================================================
  // Event Handling Logic (Core State Machine)
  // ==========================================================================

  void _handleConnectionEvent(_ConnectionEvent event) {
    i(
      '[_handleConnectionEvent] Received event: $event, Current state: $_connectedState',
    );

    switch (event) {
      case _ConnectionEvent.connect:
        // Only allow connection requests if disconnected or waiting for retry
        if (_connectedState == ConnectedState.disconnected ||
            _connectedState == ConnectedState.reconnecting ||
            _connectedState == ConnectedState.hasLocalTimeError) {
          _connect();
        } else {
          i('Ignoring connect request, state is $_connectedState');
        }

      case _ConnectionEvent.disconnect:
        if (_connectedState != ConnectedState.disconnected &&
            _connectedState != ConnectedState.disconnecting) {
          _disconnect();
        }

      case _ConnectionEvent.error:
        // Handle all error situations (including ping timeout, connection errors, etc.)
        if (_connectedState == ConnectedState.connected ||
            _connectedState == ConnectedState.connecting) {
          w(
            'Error occurred in state: $_connectedState. Initiating reconnect sequence.',
          );
          _disconnect(false);
          _connectedState = ConnectedState.reconnecting;
          _scheduleRetry();
        } else if (_connectedState == ConnectedState.reconnecting) {
          w('Error occurred during reconnect attempt. Scheduling next retry.');
          _scheduleRetry();
        } else {
          w('Ignoring error in state: $_connectedState');
        }

      case _ConnectionEvent.retry:
        // Timer triggered, attempt to reconnect
        if (_connectedState == ConnectedState.reconnecting) {
          _connect();
        } else {
          i('Ignoring retry event, state changed to $_connectedState');
        }
    }
  }

  // ==========================================================================
  // Actions Triggered by Event Handler
  // ==========================================================================

  /// Schedule a retry attempt with fixed delay
  void _scheduleRetry() {
    _reconnectTimer?.cancel(); // Cancel previous timer
    // Ensure we're in a state that should retry
    if (_connectedState != ConnectedState.reconnecting) {
      i('Not scheduling retry, state is $_connectedState');
      return;
    }

    _host = _host == _wsHost1 ? _wsHost2 : _wsHost1; // Alternate host

    const delay = Duration(seconds: _fixedReconnectDelaySeconds);
    i('Scheduling retry in $delay to host $_host...');
    _reconnectTimer = Timer(delay, () {
      i('Triggering RETRY event: Retry timer fired');
      _eventController.add(_ConnectionEvent.retry);
    });
  }

  void _connect() {
    i('reconnecting set false, ${StackTrace.current}');
    _connectedState = ConnectedState.connecting;

    try {
      i('ws connect');
      _token ??= signAuthTokenWithEdDSA(
        userId,
        sessionId,
        Key.fromBase64(privateKey),
        scp,
        'GET',
        '/',
        '',
      );
      i('ws _token?.isNotEmpty == true: ${_token?.isNotEmpty == true}');
      i('ws _userAgent: $userAgent');

      // Ensure previous resources are released before attempting new connection
      _closeChannelAndSubscription();

      channel = IOWebSocketChannel.connect(
        _host,
        protocols: ['Mixin-Blaze-1'],
        headers: {'User-Agent': userAgent, 'Authorization': 'Bearer $_token'},
        pingInterval: const Duration(seconds: 10),
        customClient: HttpClient()..setProxy(proxyConfig),
      );

      subscription = channel?.stream
          .cast<List<int>>()
          .asyncMap(parseBlazeMessage)
          .listen(
            (blazeMessage) async {
              _connectedState = ConnectedState.connected;
              d('blazeMessage receive: ${blazeMessage.toJson()}');

              if (blazeMessage.action == kErrorAction &&
                  blazeMessage.error?.code == authentication) {
                _disconnect();
                return;
              }

              if (blazeMessage.error == null) {
                final transaction = transactions[blazeMessage.id];
                if (transaction != null) {
                  d('transaction success id: ${transaction.tid}');
                  transaction.success(blazeMessage);
                  transactions.removeWhere(
                    (key, value) => key == blazeMessage.id,
                  );
                }
              } else {
                final transaction = transactions[blazeMessage.id];
                if (transaction != null) {
                  d('transaction error id: ${transaction.tid}');
                  transaction.error(blazeMessage);
                  transactions.removeWhere(
                    (key, value) => key == blazeMessage.id,
                  );
                }
              }

              if (blazeMessage.data != null &&
                  blazeMessage.isReceiveMessageAction()) {
                await handleReceiveMessage(blazeMessage);
              }
            },
            onError: (error, s) {
              i('ws error: $error, s: $s');
              i('Triggering ERROR event: WebSocket stream error');
              _eventController.add(_ConnectionEvent.error);
            },
            onDone: () {
              i('web socket done');
              // Only trigger reconnect if we were in connected state
              if (_connectedState == ConnectedState.connected) {
                i(
                  'Triggering ERROR event: WebSocket stream unexpectedly closed',
                );
                _eventController.add(_ConnectionEvent.error);
              }
            },
            cancelOnError: true,
          );

      _checkTimeoutTimer = Timer(const Duration(seconds: 10), () {
        i('ws webSocket state: ${channel?.ready}');

        if (_connectedState == ConnectedState.connected) return;

        i('ws webSocket connect timeout');
        i('Triggering ERROR event: Connection timeout');
        _eventController.add(_ConnectionEvent.error);
      });

      _sendListPending();
    } catch (error, stack) {
      e('ws connect error: $error, $stack');
      i('Triggering ERROR event: Exception during connection');
      _eventController.add(_ConnectionEvent.error);
    }
  }

  // Close channel and subscription
  void _closeChannelAndSubscription() {
    subscription?.cancel();
    channel?.sink.close();
    subscription = null;
    channel = null;
  }

  Future<void> handleReceiveMessage(BlazeMessage blazeMessage) async {
    Stopwatch? stopwatch;
    if (!kReleaseMode) {
      stopwatch = Stopwatch()..start();
    }

    BlazeMessageData? data;
    try {
      data = BlazeMessageData.fromJson(
        blazeMessage.data as Map<String, dynamic>,
      );
    } catch (e) {
      d('blazeMessage not a BlazeMessageData');
      return;
    }
    if (blazeMessage.action == kAcknowledgeMessageReceipt) {
      await makeMessageStatus(data.messageId, data.status);

      final offset =
          await database.offsetDao.findStatusOffset().getSingleOrNull();
      final timestamp = data.updatedAt.toIso8601String();

      if (offset == null || offset != timestamp) {
        await database.offsetDao.insert(
          Offset(key: statusOffset, timestamp: timestamp),
        );
      }
    } else if (blazeMessage.action == kCreateMessage) {
      if (data.userId == userId &&
          (data.category == null || data.conversationId.isEmpty)) {
        await makeMessageStatus(data.messageId, data.status);
      } else {
        await floodJob.add(
          FloodMessage(
            messageId: data.messageId,
            data: jsonEncode(data),
            createdAt: data.createdAt,
          ),
        );
      }
    } else if (blazeMessage.action == kCreateCall ||
        blazeMessage.action == kCreateKraken) {
      await ackJob.add([
        createAckJob(
          kAcknowledgeMessageReceipts,
          data.messageId,
          MessageStatus.read,
        ),
      ]);
    } else {
      await ackJob.add([
        createAckJob(
          kAcknowledgeMessageReceipts,
          data.messageId,
          MessageStatus.delivered,
        ),
      ]);
    }
    if (stopwatch != null && stopwatch.elapsedMilliseconds > 5) {
      d('handle execution time: ${stopwatch.elapsedMilliseconds}');
    }
  }

  Future<bool> makeMessageStatus(String messageId, MessageStatus status) async {
    final currentStatus =
        await database.messageDao
            .messageStatusById(messageId)
            .getSingleOrNull();

    if (currentStatus != null && status.index > currentStatus.index) {
      await database.messageDao.updateMessageStatusById(messageId, status);
      return true;
    }

    if (currentStatus == null) {
      // Check if message is in deleted messages history
      final messagesHistory = await database.messageHistoryDao
          .findMessageHistoryById(messageId);
      if (messagesHistory != null) {
        return true; // Skip status update for deleted messages
      }

      final cachedStatus = pendingMessageStatusMap[messageId];
      if (cachedStatus == null || status.index > cachedStatus.index) {
        pendingMessageStatusMap[messageId] = status;
      }
      return true;
    }

    return true;
  }

  Future<void> _sendListPending() async {
    final offset =
        await database.floodMessageDao.getLastBlazeMessageCreatedAt();
    final param = offset?.toIso8601String();
    final m = createPendingBlazeMessage(BlazeMessageParamOffset(offset: param));
    d('blaze send: ${m.toJson()}');
    await _sendGZip(m);
  }

  Future<void> _refreshOffset() async {
    final offset =
        await database.offsetDao.findStatusOffset().getSingleOrNull();
    var status = offset != null ? offset.epochNano : DateTime.now().epochNano;
    for (;;) {
      final response = await client.messageApi.messageStatusOffset(status);
      final blazeMessages = response.data;
      if (blazeMessages.isEmpty) {
        break;
      }
      await Future.forEach<BlazeMessageData>(blazeMessages, (m) async {
        // Use unified status handling logic in makeMessageStatus
        await makeMessageStatus(m.messageId, m.status);

        await database.offsetDao.insert(
          Offset(key: statusOffset, timestamp: m.updatedAt.toIso8601String()),
        );
      });
      final lastUpdateAt = blazeMessages.last.updatedAt.epochNano;
      if (lastUpdateAt == status) {
        break;
      }
      status = lastUpdateAt;
    }
  }

  Future<void> _sendGZip(BlazeMessage msg) async {
    channel?.sink.add(
      const GZipEncoder().encode(Uint8List.fromList(jsonEncode(msg).codeUnits)),
    );
  }

  void _disconnect([bool resetConnectedState = true]) {
    i('ws _disconnect');

    if (resetConnectedState) {
      _connectedState = ConnectedState.disconnected;
    }

    _checkTimeoutTimer?.cancel();
    _checkTimeoutTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    transactions.clear();
    _closeChannelAndSubscription();
  }

  void waitSyncTime() {
    _disconnect(false);
    _connectedState = ConnectedState.hasLocalTimeError;
  }

  Future<BlazeMessage?> sendMessage(BlazeMessage blazeMessage) async {
    if (_connectedState != ConnectedState.connected) {
      w('Cannot send message, not connected. State: $_connectedState');
      return null;
    }

    d('blaze send: ${blazeMessage.toJson()}');
    final transaction = WebSocketTransaction<BlazeMessage>(blazeMessage.id);
    transactions[blazeMessage.id] = transaction;
    d('sendMessage transactions size: ${transactions.length}');
    return transaction.run(
      () => channel?.sink.add(
        const GZipEncoder().encode(
          Uint8List.fromList(jsonEncode(blazeMessage).codeUnits),
        ),
      ),
      () => null,
    );
  }

  // ==========================================================================
  // Public API Methods (Event Triggers)
  // ==========================================================================

  /// Public method to request connection or reconnection

  Future<void> connect() async {
    i('Public connect called. Current state: $_connectedState');
    if (_connectedState == ConnectedState.connecting ||
        _connectedState == ConnectedState.reconnecting) {
      return;
    }

    _eventController.add(_ConnectionEvent.connect);
  }

  Future<void> reconnect() async {
    i('Public reconnect called. Current state: $_connectedState');
    if (_connectedState == ConnectedState.connecting ||
        _connectedState == ConnectedState.reconnecting) {
      return;
    }

    _connectedState = ConnectedState.reconnecting;

    try {
      // Test HTTP connection
      await client.accountApi.getMe();
      i('http ping successful');

      i('Triggering CONNECT event: User requested reconnection');
      _eventController.add(_ConnectionEvent.connect);
    } catch (e) {
      w('ws ping error: $e');
      if (e is MixinApiError &&
          e.error != null &&
          e.error is MixinError &&
          (e.error! as MixinError).code == authentication) {
        _connectedState = ConnectedState.disconnected;
        return;
      }
      i('Triggering ERROR event: HTTP ping failed');
      _eventController.add(_ConnectionEvent.error);
    }
  }

  void _onProxySettingChanged() {
    final url = database.settingProperties.activatedProxy;
    if (url == proxyConfig) {
      return;
    }
    i('Proxy settings changed to: $url');
    proxyConfig = url;

    i('Triggering DISCONNECT event: Proxy settings changed');
    _eventController.add(_ConnectionEvent.disconnect);

    // Trigger reconnect after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      i('Triggering CONNECT event: Reconnecting after proxy change');
      _eventController.add(_ConnectionEvent.connect);
    });
  }

  void dispose() {
    i('Disposing Blaze...');
    database.settingProperties.removeListener(_onProxySettingChanged);
    _eventStreamSubscription.cancel();
    _eventController.close();
    _disconnect();
    _connectedStateBehaviorSubject.close();
    i('Blaze disposed.');
  }
}

BlazeMessage parseBlazeMessage(List<int> list) =>
    _parseBlazeMessageInternal(list);

BlazeMessage _parseBlazeMessageInternal(List<int> message) {
  final content = String.fromCharCodes(
    const GZipDecoder().decodeBytes(message),
  );
  return BlazeMessage.fromJson(jsonDecode(content) as Map<String, dynamic>);
}

class WebSocketTransaction<T> {
  WebSocketTransaction(this.tid);

  final String tid;

  final Completer<T?> _completer = Completer();
  bool _isCompleted = false;
  Timer? _timeoutTimer;

  Future<T?> run(
    Function() fun,
    T? Function() onTimeout, [
    Duration timeoutDuration = const Duration(seconds: 5),
  ]) {
    if (_isCompleted) return _completer.future;

    try {
      fun.call();
      // Start timeout timer after function call succeeds
      _timeoutTimer = Timer(timeoutDuration, () {
        if (!_isCompleted) {
          w('WebSocket transaction timeout: $tid');
          _isCompleted = true;
          _completer.complete(onTimeout.call()); // Complete with timeout
        }
      });
    } catch (e, s) {
      w('Error executing transaction function for $tid: $e\n$s');
      error(null); // Complete with error
    }
    return _completer.future;
  }

  void _clearTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  void success(T? data) {
    if (!_isCompleted) {
      _clearTimeout();
      _isCompleted = true;
      _completer.complete(data);
    }
  }

  void error(T? data) {
    if (!_isCompleted) {
      _clearTimeout();
      _isCompleted = true;
      _completer.complete(data);
    }
  }
}
