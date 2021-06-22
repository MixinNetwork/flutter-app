import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:web_socket_channel/io.dart';

import '../constants/constants.dart';
import '../db/database.dart';
import '../db/extension/job.dart';
import '../db/mixin_database.dart';
import '../enum/message_status.dart';
import '../utils/dao_extension.dart';
import '../utils/datetime_format_utils.dart';
import '../utils/load_balancer_utils.dart';
import '../utils/logger.dart';
import 'blaze_message.dart';
import 'blaze_message_param_session.dart';
import 'vo/blaze_message_data.dart';

const String _wsHost1 = 'wss://blaze.mixin.one';
const String _wsHost2 = 'wss://mixin-blaze.zeromesh.net';

class Blaze {
  Blaze(
    this.userId,
    this.sessionId,
    this.privateKey,
    this.database,
    this.client,
  ) {
    connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        _reconnect();
        return;
      }

      _disconnect();
      _reconnecting = false;
    });
  }

  final String userId;
  final String sessionId;
  final String privateKey;
  final Database database;
  final Client client; // todo delete

  String _host = _wsHost1;
  bool _reconnecting = false;
  bool _disposed = false;
  String? _token;

  StreamController<bool> connectedStateStreamController =
      StreamController<bool>.broadcast();

  IOWebSocketChannel? channel;
  StreamSubscription? subscription;
  StreamSubscription? connectivitySubscription;

  final transactions = <String, WebSocketTransaction>{};

  Future<void> connect() async {
    i('reconnecting set false, ${StackTrace.current}');
    _reconnecting = false;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return _disconnect();
    }

    i('ws connect');
    _token ??= signAuthTokenWithEdDSA(
        userId, sessionId, privateKey, scp, 'GET', '/', '');
    try {
      _connect(_token!);
    } catch (_) {
      await _reconnect();
    }
  }

  void _connect(String token) {
    if (_disposed) return;
    channel = IOWebSocketChannel.connect(
      _host,
      protocols: ['Mixin-Blaze-1'],
      headers: {'Authorization': 'Bearer $token'},
      pingInterval: const Duration(seconds: 10),
    );
    subscription =
        channel?.stream.cast<List<int>>().asyncMap(parseBlazeMessage).listen(
      (blazeMessage) async {
        connectedStateStreamController.add(true);
        d('blazeMessage receive: ${blazeMessage.toJson()}');

        if (blazeMessage.action == errorAction &&
            blazeMessage.error?.code == 401) {
          await _reconnect();
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
        _reconnect();
      },
      onDone: () {
        i('web socket done');
        _reconnect();
      },
      cancelOnError: true,
    );
    _refreshOffset();
    _sendListPending();
  }

  Future<void> handleReceiveMessage(BlazeMessage blazeMessage) async {
    BlazeMessageData? data;
    try {
      data = BlazeMessageData.fromJson(blazeMessage.data);
    } catch (e) {
      d('blazeMessage not a BlazeMessageData');
      return;
    }
    if (blazeMessage.action == acknowledgeMessageReceipt) {
      await makeMessageStatus(data.messageId, data.status);
      await database.offsetsDao.insert(Offset(
          key: statusOffset, timestamp: data.updatedAt.toIso8601String()));
    } else if (blazeMessage.action == createMessage) {
      if (data.userId == userId && data.category == null) {
        await makeMessageStatus(data.messageId, data.status);
      } else {
        await database.floodMessagesDao.insert(FloodMessage(
            messageId: data.messageId,
            data: await jsonEncodeWithIsolate(data),
            createdAt: data.createdAt));
      }
    } else if (blazeMessage.action == createCall ||
        blazeMessage.action == createKraken) {
      await database.jobsDao.insertNoReplace(createAckJob(
          acknowledgeMessageReceipts, data.messageId, MessageStatus.read));
    } else {
      await database.jobsDao.insertNoReplace(createAckJob(
          acknowledgeMessageReceipts, data.messageId, MessageStatus.delivered));
    }
  }

  Future<void> updateRemoteMessageStatus(
      String messageId, MessageStatus status) async {}

  Future<void> makeMessageStatus(String messageId, MessageStatus status) async {
    final currentStatus =
        await database.messagesDao.findMessageStatusById(messageId);
    if (currentStatus != null && currentStatus.index < status.index) {
      await database.messagesDao.updateMessageStatusById(messageId, status);
    }
  }

  Future<void> _sendListPending() async {
    final offset =
        await database.floodMessagesDao.getLastBlazeMessageCreatedAt();
    final param = offset?.toIso8601String();
    final m = createPendingBlazeMessage(BlazeMessageParamOffset(offset: param));
    d('blaze send: ${m.toJson()}');
    await _sendGZip(m);
  }

  Future<void> _refreshOffset() async {
    final offset =
        await database.offsetsDao.findStatusOffset().getSingleOrNull();
    var status = 0;
    if (offset != null) {
      status = getEpochNanoFromString(offset);
    }
    for (;;) {
      final response = await client.messageApi.messageStatusOffset(status);
      final blazeMessages = <BlazeMessageData>[];
      // ignore: avoid_dynamic_calls
      response.data.forEach((itemJson) {
        blazeMessages.add(BlazeMessageData.fromJson(itemJson));
      });
      if (blazeMessages.isEmpty) {
        break;
      }
      await Future.forEach<BlazeMessageData>(blazeMessages, (m) async {
        await makeMessageStatus(m.messageId, m.status);
        await database.offsetsDao.insert(Offset(
            key: statusOffset, timestamp: m.updatedAt.toIso8601String()));
      });
      final lastUpdateAt = getEpochNano(blazeMessages.last.updatedAt);
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

  void _disconnect() {
    i('ws _disconnect');
    connectedStateStreamController.add(false);
    transactions.clear();
    subscription?.cancel();
    channel?.sink.close();
    subscription = null;
    channel = null;
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

  Future<void> _reconnect() async {
    i('_reconnect reconnecting: $_reconnecting start: ${StackTrace.current}');
    if (_reconnecting) return;
    _reconnecting = true;
    _host = _host == _wsHost1 ? _wsHost2 : _wsHost1;

    try {
      _disconnect();
      await client.accountApi.getMe();
      i('http ping');
      await connect();
    } catch (e) {
      w('ws ping error: $e');
      if (e is MixinApiError && (e.error as MixinError).code == 401) return;
      await Future.delayed(const Duration(seconds: 2));
      _reconnecting = false;
      i('reconnecting set false, ${StackTrace.current}');
      return _reconnect();
    }
  }

  void dispose() {
    _disposed = true;
    _disconnect();
    connectivitySubscription?.cancel();
    connectedStateStreamController.close();
  }
}

Future<BlazeMessage> parseBlazeMessage(List<int> list) =>
    runLoadBalancer(_parseBlazeMessageInternal, list);

BlazeMessage _parseBlazeMessageInternal(List<int> message) {
  final content = String.fromCharCodes(GZipDecoder().decodeBytes(message));
  final blazeMessage = BlazeMessage.fromJson(jsonDecode(content));
  return blazeMessage;
}

class WebSocketTransaction<T> {
  WebSocketTransaction(this.tid);

  final String tid;

  final Completer<T?> _completer = Completer();

  Future<T?> run(Function() fun, Function() onTimeout) {
    fun.call();
    return _completer.future
        .timeout(const Duration(seconds: 5), onTimeout: onTimeout.call());
  }

  void success(T? data) {
    _completer.complete(data);
  }

  void error(T? data) {
    _completer.complete(data);
  }
}
