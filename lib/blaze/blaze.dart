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

const String _wsHost1 = 'wss://blaze.mixin.one';
const String _wsHost2 = 'wss://mixin-blaze.zeromesh.net';

enum ConnectedState {
  connecting,
  reconnecting,
  connected,
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
  }

  final String userId;
  final String sessionId;
  final String privateKey;
  final Database database;
  final Client client; // todo delete
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

  ConnectedState get _connectedState => _connectedStateBehaviorSubject.value;

  set _connectedState(ConnectedState state) {
    if (_connectedStateBehaviorSubject.valueOrNull == state) return;

    _connectedStateBehaviorSubject.value = state;

    if (state == ConnectedState.connected) {
      _refreshOffset();
    }
  }

  Timer? _checkTimeoutTimer;

  Future<void> connect() async {
    i('reconnecting set false, ${StackTrace.current}');
    _connectedState = ConnectedState.connecting;

    try {
      i('ws connect');
      _token ??= signAuthTokenWithEdDSA(
          userId, sessionId, Key.fromBase64(privateKey), scp, 'GET', '/', '');
      i('ws _token?.isNotEmpty == true: ${_token?.isNotEmpty == true}');
      i('ws _userAgent: $userAgent');
      _connect(_token!);
      _checkTimeoutTimer = Timer(const Duration(seconds: 10), () {
        i('ws webSocket state: ${channel?.innerWebSocket?.readyState}');

        if (channel?.innerWebSocket?.readyState == WebSocket.open) return;
        if (_connectedState == ConnectedState.connected) return;
        _connectedState = ConnectedState.disconnected;

        i('ws webSocket connect timeout');

        reconnect();
      });
    } catch (error, stack) {
      e('ws connect error: $error, $stack');
      _connectedState = ConnectedState.disconnected;
      await reconnect();
    }
  }

  void _connect(String token) {
    _disconnect(false);
    _connectedState = ConnectedState.connecting;
    channel = IOWebSocketChannel.connect(
      _host,
      protocols: ['Mixin-Blaze-1'],
      headers: {
        'User-Agent': userAgent,
        'Authorization': 'Bearer $token',
      },
      pingInterval: const Duration(seconds: 10),
      customClient: HttpClient()..setProxy(proxyConfig),
    );
    subscription =
        channel?.stream.cast<List<int>>().asyncMap(parseBlazeMessage).listen(
      (blazeMessage) async {
        _connectedState = ConnectedState.connected;
        d('blazeMessage receive: ${blazeMessage.toJson()}');

        if (blazeMessage.action == kErrorAction &&
            blazeMessage.error?.code == authentication) {
          _connectedState = ConnectedState.disconnected;
          await reconnect();
          return;
        }

        if (blazeMessage.error == null) {
          final transaction = transactions[blazeMessage.id];
          if (transaction != null) {
            d('transaction success id: ${transaction.tid}');
            transaction.success(blazeMessage);
            transactions.removeWhere((key, value) => key == blazeMessage.id);
          }
        } else {
          final transaction = transactions[blazeMessage.id];
          if (transaction != null) {
            d('transaction error id: ${transaction.tid}');
            transaction.error(blazeMessage);
            transactions.removeWhere((key, value) => key == blazeMessage.id);
          }
        }

        if (blazeMessage.data != null &&
            blazeMessage.isReceiveMessageAction()) {
          await handleReceiveMessage(blazeMessage);
        }
      },
      onError: (error, s) {
        i('ws error: $error, s: $s');
        _connectedState = ConnectedState.disconnected;
        reconnect();
      },
      onDone: () {
        i('web socket done');
        _connectedState = ConnectedState.disconnected;
        reconnect();
      },
      cancelOnError: true,
    );
    _sendListPending();
  }

  Future<void> handleReceiveMessage(BlazeMessage blazeMessage) async {
    Stopwatch? stopwatch;
    if (!kReleaseMode) {
      stopwatch = Stopwatch()..start();
    }

    BlazeMessageData? data;
    try {
      data =
          BlazeMessageData.fromJson(blazeMessage.data as Map<String, dynamic>);
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
        await floodJob.add(FloodMessage(
            messageId: data.messageId,
            data: jsonEncode(data),
            createdAt: data.createdAt));
      }
    } else if (blazeMessage.action == kCreateCall ||
        blazeMessage.action == kCreateKraken) {
      await ackJob.add([
        createAckJob(
            kAcknowledgeMessageReceipts, data.messageId, MessageStatus.read)
      ]);
    } else {
      await ackJob.add([
        createAckJob(kAcknowledgeMessageReceipts, data.messageId,
            MessageStatus.delivered)
      ]);
    }
    if (stopwatch != null && stopwatch.elapsedMilliseconds > 5) {
      d('handle execution time: ${stopwatch.elapsedMilliseconds}');
    }
  }

  Future<bool> makeMessageStatus(String messageId, MessageStatus status) async {
    final currentStatus = await database.messageDao
        .messageStatusById(messageId)
        .getSingleOrNull();
    if (currentStatus != null && status.index > currentStatus.index) {
      await database.messageDao.updateMessageStatusById(messageId, status);
    }
    return currentStatus != null;
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
        if (!(await makeMessageStatus(m.messageId, m.status))) {
          final messagesHistory = await database.messageHistoryDao
              .findMessageHistoryById(m.messageId);
          if (messagesHistory != null) return;

          final status = pendingMessageStatusMap[m.messageId];
          if (status == null || m.status.index > status.index) {
            pendingMessageStatusMap[m.messageId] = m.status;
          }
        }

        await database.offsetDao.insert(Offset(
            key: statusOffset, timestamp: m.updatedAt.toIso8601String()));
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
        GZipEncoder().encode(Uint8List.fromList(jsonEncode(msg).codeUnits)));
  }

  void _disconnect([bool resetConnectedState = true]) {
    i('ws _disconnect');
    if (resetConnectedState) _connectedState = ConnectedState.disconnected;
    _checkTimeoutTimer?.cancel();
    transactions.clear();
    subscription?.cancel();
    channel?.sink.close();
    subscription = null;
    channel = null;
    _checkTimeoutTimer = null;
  }

  void waitSyncTime() {
    _disconnect();
    _connectedState = ConnectedState.hasLocalTimeError;
  }

  Future<BlazeMessage?> sendMessage(BlazeMessage blazeMessage) async {
    d('blaze send: ${blazeMessage.toJson()}');
    final transaction = WebSocketTransaction<BlazeMessage>(blazeMessage.id);
    transactions[blazeMessage.id] = transaction;
    d('sendMessage transactions size: ${transactions.length}');
    return transaction.run(
        () => channel?.sink.add(GZipEncoder()
            .encode(Uint8List.fromList(jsonEncode(blazeMessage).codeUnits))),
        () => null);
  }

  Future<void> reconnect() async {
    i('_reconnect reconnecting: $_connectedState start: ${StackTrace.current}');
    if (_connectedState == ConnectedState.connecting ||
        _connectedState == ConnectedState.reconnecting) {
      return;
    }
    _connectedState = ConnectedState.reconnecting;
    _host = _host == _wsHost1 ? _wsHost2 : _wsHost1;

    try {
      _disconnect(false);
      await client.accountApi.getMe();
      i('http ping');
      await connect();
    } catch (e) {
      w('ws ping error: $e');
      if (e is MixinApiError &&
          e.error != null &&
          e.error is MixinError &&
          (e.error! as MixinError).code == authentication) {
        _connectedState = ConnectedState.disconnected;
        return;
      }
      _connectedState = ConnectedState.disconnected;
      await Future.delayed(const Duration(seconds: 2));
      i('reconnecting set false, ${StackTrace.current}');
      await reconnect();
    }
  }

  void _onProxySettingChanged() {
    final url = database.settingProperties.activatedProxy;
    if (url == proxyConfig) {
      return;
    }
    proxyConfig = url;
    _connectedState = ConnectedState.disconnected;
    reconnect();
  }

  void dispose() {
    database.settingProperties.removeListener(_onProxySettingChanged);
    _disconnect();
    _connectedStateBehaviorSubject.close();
  }
}

BlazeMessage parseBlazeMessage(List<int> list) =>
    _parseBlazeMessageInternal(list);

BlazeMessage _parseBlazeMessageInternal(List<int> message) {
  final content = String.fromCharCodes(GZipDecoder().decodeBytes(message));
  return BlazeMessage.fromJson(jsonDecode(content) as Map<String, dynamic>);
}

class WebSocketTransaction<T> {
  WebSocketTransaction(this.tid);

  final String tid;

  final Completer<T?> _completer = Completer();

  Future<T?> run(Function() fun, T? Function() onTimeout) {
    fun.call();
    return _completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => onTimeout.call(),
    );
  }

  void success(T? data) {
    _completer.complete(data);
  }

  void error(T? data) {
    _completer.complete(data);
  }
}
