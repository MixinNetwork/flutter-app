import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/db/converter/message_status_type_converter.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/constants.dart';
import '../db/database.dart';
import '../db/mixin_database.dart';
import '../enum/message_status.dart';
import '../utils/load_Balancer_utils.dart';
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

  Future<void> connect() async {
    final token = signAuthTokenWithEdDSA(
        userId, sessionId, privateKey, scp, 'GET', '/', '');
    _connect(token);
  }

  void _connect(String token) {
    if (disposed) return;
    channel = IOWebSocketChannel.connect(host,
        protocols: ['Mixin-Blaze-1'],
        headers: {'Authorization': 'Bearer $token'},
        pingInterval: const Duration(seconds: 15));
    channel?.stream
        .asyncMap((message) async => await parseBlazeMessage(message))
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
          updateRemoteMessageStatus(
              data['message_id'], MessageStatus.delivered);
        } else if (blazeMessage.action == createMessage) {
          final messageData = BlazeMessageData.fromJson(data);
          if (messageData.userId == userId && messageData.category == null) {
            updateRemoteMessageStatus(
                messageData.messageId, MessageStatus.delivered);
          } else {
            await database.floodMessagesDao.insert(FloodMessage(
                messageId: messageData.messageId,
                data: jsonEncode(data),
                createdAt: messageData.createdAt));
          }
        } else if (blazeMessage.action == acknowledgeMessageReceipt) {
          await makeMessageStatus(data['message_id'],
              const MessageStatusTypeConverter().mapToDart(data['status'])!);
          updateRemoteMessageStatus(
              data['message_id'], MessageStatus.delivered);
        } else {
          updateRemoteMessageStatus(
              data['message_id'], MessageStatus.delivered);
        }
      },
      onError: (error, s) {
        debugPrint('fuck ws error: $error, s: $s');
        if (error is WebSocketChannelException) _reconnect();
      },
      onDone: () {
        debugPrint('web socket done');
        _reconnect();
      },
      cancelOnError: true,
    );
    _sendListPending();
  }

  void updateRemoteMessageStatus(String messageId, MessageStatus status) {
    final blazeMessage = BlazeAckMessage(
        messageId: messageId,
        status: EnumToString.convertToString(status)!.toUpperCase());
    database.jobsDao.insert(Job(
        jobId: const Uuid().v4(),
        action: acknowledgeMessageReceipts,
        priority: 5,
        blazeMessage: jsonEncode(blazeMessage),
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

  void _sendListPending() async {
    final offset =
        await database.floodMessagesDao.getLastBlazeMessageCreatedAt();
    // ignore: prefer_typing_uninitialized_variables
    var params;
    if (offset != null) {
      params = '{"offset":"${offset.toUtc()}"}';
    }
    _sendGZip(BlazeMessage(
        id: const Uuid().v4(),
        params: params,
        action: 'LIST_PENDING_MESSAGES'));
  }

  void _sendGZip(BlazeMessage msg) {
    channel?.sink.add(
        GZipEncoder().encode(Uint8List.fromList(jsonEncode(msg).codeUnits)));
  }

  void deliver(BlazeMessage blazeMessage) {
    // todo check send callback
    channel?.sink.add(GZipEncoder()
        .encode(Uint8List.fromList(jsonEncode(blazeMessage).codeUnits)));
  }

  Future<void> _disconnect() async {
    await channel?.sink.close();
  }

  Future<void> _reconnect() async {
    if (reconnecting) return;
    reconnecting = true;
    host = host == _wsHost1 ? _wsHost2 : _wsHost1;

    await _disconnect();
    try {
      await client.accountApi.getMe();
      await Future.delayed(const Duration(seconds: 2));
      await connect();
    } catch (e) {
      if (e is MixinApiError && e.error.code == 401) return;
      await Future.delayed(const Duration(seconds: 2));
      return await _reconnect();
    } finally {
      reconnecting = false;
    }
  }

  Future<void> dispose() async {
    disposed = true;
    await _disconnect();
  }
}

Future<BlazeMessage> parseBlazeMessage(List<int> message) =>
    LoadBalancerUtils.runLoadBalancer(_parseBlazeMessageInternal, message);

BlazeMessage _parseBlazeMessageInternal(List<int> message) {
  final content = String.fromCharCodes(GZipDecoder().decodeBytes(message));
  final blazeMessage = BlazeMessage.fromJson(jsonDecode(content));
  return blazeMessage;
}
