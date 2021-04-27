import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/blaze/vo/message_result.dart';
import 'package:flutter_app/db/converter/message_status_type_converter.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';

import '../constants/constants.dart';
import '../db/converter/message_status_type_converter.dart';
import '../db/database.dart';
import '../db/mixin_database.dart';
import '../enum/message_status.dart';
import '../utils/load_balancer_utils.dart';
import 'blaze_message.dart';
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
  );

  final String userId;
  final String sessionId;
  final String privateKey;
  final Database database;
  final Client client; // todo delete

  String host = _wsHost1;
  bool reconnecting = false;
  bool disposed = false;
  String? token;

  IOWebSocketChannel? channel;
  StreamSubscription? subscription;

  final transactions = <String, WebSocketTransaction>{};

  void connect() {
    debugPrint('ws connect');
    token ??= signAuthTokenWithEdDSA(
        userId, sessionId, privateKey, scp, 'GET', '/', '');
    _connect(token!);
  }

  void _connect(String token) {
    if (disposed) return;
    channel = IOWebSocketChannel.connect(
      host,
      protocols: ['Mixin-Blaze-1'],
      headers: {'Authorization': 'Bearer $token'},
      pingInterval: const Duration(seconds: 15),
    );
    subscription = channel?.stream
        .asyncMap((message) async => parseBlazeMessage(message, transactions))
        .listen(
      (blazeMessage) async {
        debugPrint('blazeMessage: ${blazeMessage.toJson()}');

        if (blazeMessage.action == errorAction &&
            blazeMessage.error?.code == 401) {
          await _reconnect();
        }

        final data = blazeMessage.data;
        if (data == null) {
          return;
        }
        if (blazeMessage.action == acknowledgeMessageReceipts) {
          // makeMessageStatus
          await updateRemoteMessageStatus(
              data['message_id'], MessageStatus.delivered);
        } else if (blazeMessage.action == createMessage) {
          final messageData = BlazeMessageData.fromJson(data);
          if (messageData.userId == userId && messageData.category == null) {
            await updateRemoteMessageStatus(
                messageData.messageId, MessageStatus.delivered);
          } else {
            await database.floodMessagesDao.insert(FloodMessage(
                messageId: messageData.messageId,
                data: await jsonEncodeWithIsolate(data),
                createdAt: messageData.createdAt));
          }
        } else if (blazeMessage.action == acknowledgeMessageReceipt) {
          await makeMessageStatus(data['message_id'],
              const MessageStatusTypeConverter().mapToDart(data['status'])!);
          await updateRemoteMessageStatus(
              data['message_id'], MessageStatus.delivered);
        } else {
          await updateRemoteMessageStatus(
              data['message_id'], MessageStatus.delivered);
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
  }

  Future<void> updateRemoteMessageStatus(
      String messageId, MessageStatus status) async {
    final blazeMessage = BlazeAckMessage(
        messageId: messageId,
        status: EnumToString.convertToString(status)!.toUpperCase());
    await database.jobsDao.insert(Job(
        jobId: const Uuid().v4(),
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
    subscription?.cancel();
    channel?.sink.close();
    subscription = null;
    channel = null;
  }

  Future<MessageResult> deliverNoThrow(BlazeMessage blazeMessage) async {
    final transaction = WebSocketTransaction<BlazeMessage>(blazeMessage.id);
    transactions[blazeMessage.id] = transaction;
    final bm = await transaction.run(() => channel?.sink.add(GZipEncoder()
        .encode(Uint8List.fromList(jsonEncode(blazeMessage).codeUnits))));
    if (bm == null) {
      return await deliverNoThrow(blazeMessage);
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
    return transaction.run(() => channel?.sink.add(GZipEncoder()
        .encode(Uint8List.fromList(jsonEncode(blazeMessage).codeUnits))));
  }

  Future<void> _reconnect() async {
    debugPrint(
        '_reconnect reconnecting: $reconnecting start: ${StackTrace.current}');

    if (reconnecting) return;
    reconnecting = true;
    host = host == _wsHost1 ? _wsHost2 : _wsHost1;

    try {
      _disconnect();
      await client.accountApi.getMe();
      debugPrint('http ping');
      await Future.delayed(const Duration(seconds: 2));
      reconnecting = false;
      debugPrint('reconnecting set false, ${StackTrace.current}');
      connect();
    } catch (e) {
      debugPrint('ws ping error: $e');
      if (e is MixinApiError && e.error.code == 401) return;
      await Future.delayed(const Duration(seconds: 2));
      reconnecting = false;
      debugPrint('reconnecting set false, ${StackTrace.current}');
      return _reconnect();
    }
  }

  void dispose() {
    disposed = true;
    _disconnect();
  }
}

Future<BlazeMessage> parseBlazeMessage(
        List<int> message, Map<String, WebSocketTransaction> transactions) =>
    runLoadBalancer(
        _parseBlazeMessageInternal, Tuple2(message, transactions));

BlazeMessage _parseBlazeMessageInternal(
    Tuple2<List<int>, Map<String, WebSocketTransaction>> tuple2) {
  final message = tuple2.item1;
  final transactions = tuple2.item2;
  final content = String.fromCharCodes(GZipDecoder().decodeBytes(message));
  final blazeMessage = BlazeMessage.fromJson(jsonDecode(content));
  if (blazeMessage.error == null) {
    final transaction = transactions[blazeMessage.id];
    if (transaction != null) {
      transaction.success(blazeMessage);
      transactions.removeWhere((key, value) => key == blazeMessage.id);
    }
  } else {
    final transaction = transactions[blazeMessage.id];
    if (transaction != null) {
      transaction.error(blazeMessage);
      transactions.removeWhere((key, value) => key == blazeMessage.id);
    }
  }
  return blazeMessage;
}

class WebSocketTransaction<T> {
  WebSocketTransaction(this.tid);

  final String tid;

  final Completer<T?> _completer = Completer();

  Future<T?> run(Function() fun) {
    fun.call();
    return _completer.future.timeout(const Duration(seconds: 5));
  }

  void success(T? data) {
    _completer.complete(data);
  }

  void error(T? data) {
    _completer.completeError(error);
  }
}
