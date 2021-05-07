import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
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

  IOWebSocketChannel? channel;
  StreamSubscription? subscription;

  void connect() {
    final token = signAuthTokenWithEdDSA(
        userId, sessionId, privateKey, scp, 'GET', '/', '');
    _connect(token);
  }

  void _connect(String token) {
    if (disposed) return;
    channel = IOWebSocketChannel.connect(
      host,
      protocols: ['Mixin-Blaze-1'],
      headers: {'Authorization': 'Bearer $token'},
      pingInterval: const Duration(seconds: 15),
    );
    subscription =
        channel?.stream.cast<List<int>>().asyncMap(parseBlazeMessage).listen(
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

Future<BlazeMessage> parseBlazeMessage(List<int> message) =>
    runLoadBalancer(_parseBlazeMessageInternal, message);

BlazeMessage _parseBlazeMessageInternal(List<int> message) {
  final content = String.fromCharCodes(GZipDecoder().decodeBytes(message));
  final blazeMessage = BlazeMessage.fromJson(jsonDecode(content));
  return blazeMessage;
}
