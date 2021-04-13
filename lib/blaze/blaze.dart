import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/db/converter/message_status_type_converter.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';

import '../constants/constants.dart';
import '../db/database.dart';
import '../db/mixin_database.dart';
import '../enum/message_status.dart';
import '../utils/load_Balancer_utils.dart';
import 'blaze_message.dart';
import 'vo/blaze_message_data.dart';

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

  late IOWebSocketChannel channel;

  void connect() {
    final token = signAuthTokenWithEdDSA(
        userId, sessionId, privateKey, scp, 'GET', '/', '');
    _connect(token);
  }

  void _connect(String token) {
    channel = IOWebSocketChannel.connect('wss://blaze.mixin.one',
        protocols: ['Mixin-Blaze-1'],
        headers: {'Authorization': 'Bearer $token'},
        pingInterval: const Duration(seconds: 15));
    channel.stream
        .asyncMap((message) async => await parseBlazeMessage(message))
        .listen(
      (blazeMessage) async {
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
            await database.floodMessagesDao
                .insert(FloodMessage(
                    messageId: messageData.messageId,
                    data: jsonEncode(data),
                    createdAt: messageData.createdAt))
                .then((value) {});
          }
        } else if (blazeMessage.action == acknowledgeMessageReceipt) {
          await makeMessageStatus(data['message_id'],const MessageStatusTypeConverter().mapToDart(data['status'])!);
          updateRemoteMessageStatus(
              data['message_id'], MessageStatus.delivered);
        } else {
          updateRemoteMessageStatus(
              data['message_id'], MessageStatus.delivered);
        }
      },
      onError: (error) {
        debugPrint('onError');
      },
      onDone: () {
        debugPrint('onDone');
      },
      cancelOnError: true,
    );
    _sendListPending();
  }

  void updateRemoteMessageStatus(String messageId, MessageStatus status) {
    final blazeMessage = BlazeAckMessage(
        messageId: messageId, status: EnumToString.convertToString(status)!.toUpperCase());
    database.jobsDao.insert(Job(
        jobId: const Uuid().v4(),
        action: acknowledgeMessageReceipts,
        priority: 5,
        blazeMessage: jsonEncode(blazeMessage),
        createdAt: DateTime.now(),
        runCount: 0));
  }

  Future<void> makeMessageStatus(String messageId, MessageStatus status) async {
    final currentStatus = await database.messagesDao.findMessageStatusById(messageId);
    if(currentStatus.index < status.index){
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
    _sendGZip(
        BlazeMessage(
        id: const Uuid().v4(),
        params: params,
        action: 'LIST_PENDING_MESSAGES'));
  }

  void _sendGZip(BlazeMessage msg) {
    channel.sink.add(
        GZipEncoder().encode(Uint8List.fromList(jsonEncode(msg).codeUnits)));
  }

  void deliver(BlazeMessage blazeMessage) {
    // todo check send callback
    channel.sink.add(GZipEncoder()
        .encode(Uint8List.fromList(jsonEncode(blazeMessage).codeUnits)));
  }

  Future<void> disconnect() async {
    await channel.sink.close();
  }
}

Future<BlazeMessage> parseBlazeMessage(List<int> message) =>
    LoadBalancerUtils.runLoadBalancer(_parseBlazeMessageInternal, message);

BlazeMessage _parseBlazeMessageInternal(List<int> message) {
  final content = String.fromCharCodes(GZipDecoder().decodeBytes(message));
  final blazeMessage = BlazeMessage.fromJson(jsonDecode(content));
  return blazeMessage;
}
