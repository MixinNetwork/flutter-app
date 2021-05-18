import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';

import '../constants/constants.dart';
import '../db/database.dart';
import '../db/mixin_database.dart';
import '../enum/message_status.dart';
import '../utils/load_balancer_utils.dart';
import 'blaze_message.dart';
import 'vo/blaze_message_data.dart';
import 'vo/message_result.dart';

const String _wsHost1 = 'wss://blaze.mixin.one';
const String _wsHost2 = 'wss://mixin-blaze.zeromesh.net';

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
  bool _reconnecting = false;
  bool _disposed = false;
  String? _token;

  StreamController<bool> connectedStateStreamController =
      StreamController<bool>.broadcast();

  IOWebSocketChannel? channel;
  StreamSubscription? subscription;

  final transactions = <String, WebSocketTransaction>{};

  void connect() {
    debugPrint('ws connect');
    _token ??= signAuthTokenWithEdDSA(
        userId, sessionId, privateKey, scp, 'GET', '/', '');
    try {
      _connect(_token!);
    } catch (_) {
      _reconnect();
    }
  }

  void _connect(String token) {
    if (_disposed) return;
    channel = IOWebSocketChannel.connect(
      _host,
      protocols: ['Mixin-Blaze-1'],
      headers: {'Authorization': 'Bearer $token'},
      pingInterval: const Duration(seconds: 4),
    );
    subscription =
        channel?.stream.cast<List<int>>().asyncMap(parseBlazeMessage).listen(
      (blazeMessage) async {
        debugPrint('blazeMessage: ${blazeMessage.toJson()}');

        if (blazeMessage.action == errorAction &&
            blazeMessage.error?.code == 401) {
          await _reconnect();
        }

        if (blazeMessage.error == null) {
          final transaction = transactions[blazeMessage.id];
          if (transaction != null) {
            debugPrint('transaction success id: ${transaction.tid}');
            transaction.success(blazeMessage);
            transactions.removeWhere((key, value) => key == blazeMessage.id);
          }
        } else {
          final transaction = transactions[blazeMessage.id];
          if (transaction != null) {
            debugPrint('transaction error id: ${transaction.tid}');
            transaction.error(blazeMessage);
            transactions.removeWhere((key, value) => key == blazeMessage.id);
          }
        }

        BlazeMessageData? data;
        try {
          data = BlazeMessageData.fromJson(blazeMessage.data);
        } catch (e) {
          debugPrint('blazeMessage not a BlazeMessageData');
          return;
        }
        if (blazeMessage.action == acknowledgeMessageReceipts) {
          // makeMessageStatus
          await updateRemoteMessageStatus(
              (data as Map<String, dynamic>)['message_id'],
              MessageStatus.delivered);
        } else if (blazeMessage.action == createMessage) {
          if (data.userId == userId && data.category == null) {
            await updateRemoteMessageStatus(
                data.messageId, MessageStatus.delivered);
          } else {
            await database.floodMessagesDao.insert(FloodMessage(
                messageId: data.messageId,
                data: await jsonEncodeWithIsolate(data),
                createdAt: data.createdAt));
          }
        } else if (blazeMessage.action == acknowledgeMessageReceipt) {
          await makeMessageStatus(data.messageId, data.status);
          await updateRemoteMessageStatus(
              data.messageId, MessageStatus.delivered);
        } else {
          await updateRemoteMessageStatus(
              data.messageId, MessageStatus.delivered);
        }
      },
      onError: (error, s) {
        debugPrint('ws error: $error, s: $s');
        _reconnect();
      },
      onDone: () {
        debugPrint('web socket done');
        _reconnect();
      },
      cancelOnError: true,
    );
    _sendListPending();

    connectedStateStreamController.add(true);
  }

  Future<void> updateRemoteMessageStatus(
      String messageId, MessageStatus status) async {
    final blazeMessage = BlazeAckMessage(
        messageId: messageId,
        status: EnumToString.convertToString(status)!.toUpperCase());
    final jobId = const Uuid().v4();
    // final jobId = Ulid.fromBytes(utf8.encode('$messageId${blazeMessage.status}$acknowledgeMessageReceipts')).toString();
    // final job = await database.jobsDao.findAckJobById(jobId);
    // if (job != null) {
    //   return;
    // }
    await database.jobsDao.insert(Job(
        jobId: jobId,
        action: acknowledgeMessageReceipts,
        priority: 5,
        blazeMessage: await jsonEncodeWithIsolate(blazeMessage),
        createdAt: DateTime.now(),
        runCount: 0));
  }

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
    // ignore: prefer_typing_uninitialized_variables
    var params;
    if (offset != null) {
      params = '{"offset":"${offset.toUtc()}"}';
    }
    await _sendGZip(
      BlazeMessage(
          id: const Uuid().v4(),
          params: params,
          action: 'LIST_PENDING_MESSAGES'),
    );
  }

  Future<void> _sendGZip(BlazeMessage msg) async {
    channel?.sink.add(GZipEncoder().encode(
        Uint8List.fromList((await jsonEncodeWithIsolate(msg)).codeUnits)));
  }

  Future<void> deliver(BlazeMessage blazeMessage) async {
    // todo check send callback
    channel?.sink.add(GZipEncoder().encode(Uint8List.fromList(
        (await jsonEncodeWithIsolate(blazeMessage)).codeUnits)));
  }

  void _disconnect() {
    debugPrint('ws _disconnect');
    transactions.clear();
    subscription?.cancel();
    channel?.sink.close();
    subscription = null;
    channel = null;
  }

  Future<MessageResult> deliverNoThrow(BlazeMessage blazeMessage) async {
    final transaction = WebSocketTransaction<BlazeMessage>(blazeMessage.id);
    transactions[blazeMessage.id] = transaction;
    debugPrint('deliverNoThrow transactions size: ${transactions.length}');
    final bm = await transaction.run(
        () => channel?.sink.add(GZipEncoder()
            .encode(Uint8List.fromList(jsonEncode(blazeMessage).codeUnits))),
        () => null);
    if (bm == null) {
      return deliverNoThrow(blazeMessage);
    } else if (bm.error != null) {
      // TODO
      return MessageResult(false, true);
    } else {
      return MessageResult(true, false);
    }
  }

  Future<BlazeMessage?> deliverAndWait(BlazeMessage blazeMessage) {
    final transaction = WebSocketTransaction<BlazeMessage>(blazeMessage.id);
    transactions[blazeMessage.id] = transaction;
    debugPrint('deliverAndWait transactions size: ${transactions.length}');
    return transaction.run(
        () => channel?.sink.add(GZipEncoder()
            .encode(Uint8List.fromList(jsonEncode(blazeMessage).codeUnits))),
        () => null);
  }

  Future<void> _reconnect() async {
    debugPrint(
        '_reconnect reconnecting: $_reconnecting start: ${StackTrace.current}');
    if (_reconnecting) return;
    connectedStateStreamController.add(false);
    _reconnecting = true;
    _host = _host == _wsHost1 ? _wsHost2 : _wsHost1;

    try {
      _disconnect();
      await client.accountApi.getMe();
      debugPrint('http ping');
      _reconnecting = false;
      debugPrint('reconnecting set false, ${StackTrace.current}');
      connect();
    } catch (e) {
      debugPrint('ws ping error: $e');
      if (e is MixinApiError && e.error.code == 401) return;
      await Future.delayed(const Duration(seconds: 2));
      _reconnecting = false;
      debugPrint('reconnecting set false, ${StackTrace.current}');
      return _reconnect();
    }
  }

  void dispose() {
    _disposed = true;
    _disconnect();
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
    _completer.completeError(error);
  }
}
