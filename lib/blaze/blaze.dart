import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/io.dart';

import '../constants/constants.dart';
import '../db/database.dart';
import '../db/extension/job.dart';
import '../db/mixin_database.dart';
import '../enum/message_status.dart';
import '../main.dart';
import '../utils/extension/extension.dart';
import '../utils/load_balancer_utils.dart';
import '../utils/logger.dart';
import 'blaze_message.dart';
import 'blaze_message_param_session.dart';
import 'vo/blaze_message_data.dart';

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
  );

  final String userId;
  final String sessionId;
  final String privateKey;
  final Database database;
  final Client client; // todo delete

  String _host = _wsHost1;
  String? _token;

  final BehaviorSubject<ConnectedState> _connectedStateBehaviorSubject =
      BehaviorSubject<ConnectedState>();

  ValueStream<ConnectedState> get connectedStateStream =>
      _connectedStateBehaviorSubject.stream;

  IOWebSocketChannel? channel;
  StreamSubscription? subscription;

  final transactions = <String, WebSocketTransaction>{};

  String? _userAgent;

  ConnectedState get _connectedState => _connectedStateBehaviorSubject.value;

  set _connectedState(ConnectedState state) =>
      _connectedStateBehaviorSubject.value = state;

  Timer? _checkTimeoutTimer;

  Future<void> connect() async {
    i('reconnecting set false, ${StackTrace.current}');
    _connectedState = ConnectedState.connecting;

    try {
      i('ws connect');
      _token ??= signAuthTokenWithEdDSA(
          userId, sessionId, privateKey, scp, 'GET', '/', '');
      i('ws _token?.isNotEmpty == true: ${_token?.isNotEmpty == true}');
      _userAgent ??= await _getUserAgent();
      i('ws _userAgent: $_userAgent');
      _connect(_token!);
      _checkTimeoutTimer = Timer(const Duration(seconds: 10), () {
        i('ws webSocket state: ${channel?.innerWebSocket?.readyState}');

        if (channel?.innerWebSocket?.readyState == WebSocket.open) return;
        if (_connectedState == ConnectedState.connected) return;
        _connectedState = ConnectedState.disconnected;

        i('ws webSocket connect timeout');

        reconnect();
      });
    } catch (_) {
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
        'User-Agent': _userAgent,
        'Authorization': 'Bearer $token',
      },
      pingInterval: const Duration(seconds: 10),
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
    _refreshOffset();
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
      await database.offsetDao.insert(Offset(
          key: statusOffset, timestamp: data.updatedAt.toIso8601String()));
    } else if (blazeMessage.action == kCreateMessage) {
      if (data.userId == userId &&
          (data.category == null || data.conversationId.isEmpty)) {
        await makeMessageStatus(data.messageId, data.status);
      } else {
        await database.floodMessageDao.insert(FloodMessage(
            messageId: data.messageId,
            data: await jsonEncodeWithIsolate(data),
            createdAt: data.createdAt));
      }
    } else if (blazeMessage.action == kCreateCall ||
        blazeMessage.action == kCreateKraken) {
      await database.jobDao.insertNoReplace(createAckJob(
          kAcknowledgeMessageReceipts, data.messageId, MessageStatus.read));
    } else {
      await database.jobDao.insertNoReplace(createAckJob(
          kAcknowledgeMessageReceipts,
          data.messageId,
          MessageStatus.delivered));
    }
    if (stopwatch != null) {
      d('handle execution time: ${stopwatch.elapsedMilliseconds}');
    }
  }

  Future<void> updateRemoteMessageStatus(
      String messageId, MessageStatus status) async {}

  Future<void> makeMessageStatus(String messageId, MessageStatus status) async {
    final currentStatus =
        await database.messageDao.findMessageStatusById(messageId);
    if (currentStatus == MessageStatus.sending) {
      await database.messageDao.updateMessageStatusById(messageId, status);
    } else if (currentStatus == MessageStatus.sent &&
        (status == MessageStatus.delivered || status == MessageStatus.read)) {
      await database.messageDao.updateMessageStatusById(messageId, status);
    } else if (currentStatus == MessageStatus.delivered &&
        status == MessageStatus.read) {
      await database.messageDao.updateMessageStatusById(messageId, status);
    }
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
    var status = 0;
    if (offset != null) {
      status = offset.epochNano;
    } else {
      status = DateTime.now().epochNano;
    }
    for (;;) {
      final response = await client.messageApi.messageStatusOffset(status);
      final blazeMessages = (response.data as List<dynamic>? ?? [])
          .map((itemJson) =>
              BlazeMessageData.fromJson(itemJson as Map<String, dynamic>))
          .toList();
      if (blazeMessages.isEmpty) {
        break;
      }
      await Future.forEach<BlazeMessageData>(blazeMessages, (m) async {
        await makeMessageStatus(m.messageId, m.status);
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
    channel?.sink.add(GZipEncoder().encode(
        Uint8List.fromList((await jsonEncodeWithIsolate(msg)).codeUnits)));
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
      _disconnect();
      await client.accountApi.getMe();
      i('http ping');
      await connect();
    } catch (e) {
      w('ws ping error: $e');
      if (e is MixinApiError &&
          (e.error as MixinError).code == authentication) {
        _connectedState = ConnectedState.disconnected;
        return;
      }
      await Future.delayed(const Duration(seconds: 2));
      _connectedState = ConnectedState.disconnected;
      i('reconnecting set false, ${StackTrace.current}');
      return reconnect();
    }
  }

  void dispose() {
    _disconnect();
    _connectedStateBehaviorSubject.close();
  }
}

Future<BlazeMessage> parseBlazeMessage(List<int> list) =>
    runLoadBalancer(_parseBlazeMessageInternal, list);

BlazeMessage _parseBlazeMessageInternal(List<int> message) {
  final content = String.fromCharCodes(GZipDecoder().decodeBytes(message));
  final blazeMessage =
      BlazeMessage.fromJson(jsonDecode(content) as Map<String, dynamic>);
  return blazeMessage;
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

Future<String> _getUserAgent() async {
  final version = await packageInfoFuture;
  String? systemAndVersion;
  if (Platform.isMacOS) {
    try {
      final result = await Process.run('sw_vers', []);
      if (result.stdout != null) {
        final stdout = result.stdout as String;
        final map = Map.fromEntries(const LineSplitter()
            .convert(stdout)
            .map((e) => e.split(':'))
            .where((element) => element.length >= 2)
            .map((e) => MapEntry(e[0].trim(), e[1].trim())));
        // example
        // ProductName: macOS
        // ProductVersion: 12.0.1
        // BuildVersion: 21A559
        systemAndVersion =
            '${map['ProductName']} ${map['ProductVersion']}(${map['BuildVersion']})';
      }
    } catch (e) {
      w('ws mac get user agent error: $e');
    }
  }
  systemAndVersion ??=
      '${Platform.operatingSystem}(${Platform.operatingSystemVersion})';
  return 'Mixin/${version.version} (Flutter $systemAndVersion; ${Platform.localeName})';
}
