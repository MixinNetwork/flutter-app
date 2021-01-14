import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';

import 'blaze_message.dart';

class Blaze {
  Blaze(
      this.selfId, this.sessionId, this.privateKey, this.database, this.client);

  final String selfId;
  final String sessionId;
  final String privateKey;
  final Database database;
  final Client client; // todo delete

  IOWebSocketChannel channel;

  void connect() {
    final token = signAuthTokenWithEdDSA(
        selfId, sessionId, privateKey, scp, 'GET', '/', '');
    _connect(token);
  }

  void _connect(String token) {
    channel = IOWebSocketChannel.connect('wss://blaze.mixin.one',
        protocols: ['Mixin-Blaze-1'],
        headers: {'Authorization': 'Bearer $token'},
        pingInterval: const Duration(seconds: 15));
    channel.stream.listen((message) async {
      final blazeMessage = await parseBlazeMessage(message);
      final data = blazeMessage['data'];
      debugPrint('receive: ${data['message_id']}');
      if (blazeMessage['action'] == 'ACKNOWLEDGE_MESSAGE_RECEIPT') {
        // makeMessageStatus
      } else if (blazeMessage['action'] == 'CREATE_MESSAGE') {
        if (data['user_id'] == selfId && data['category'] == '') {
          // makeMessageStatus
        } else {
          if (await database.floodMessagesDao
                  .findFloodMessageById(data['message_id']) ==
              null) {
            await database.floodMessagesDao
                .insert(FloodMessage(
                    messageId: data['message_id'],
                    data: jsonEncode(data),
                    createdAt: DateTime.parse(data['created_at'])))
                .then((value) {
              updateRemoteMessageStatus(data['message_id'], 'DELIVERED');
            });
          }
        }
      } else {
        debugPrint(data.toString());
        updateRemoteMessageStatus(data['message_id'], 'DELIVERED');
      }
    }, onError: (error) {
      debugPrint('onError');
    }, onDone: () {
      debugPrint('onDone');
    }, cancelOnError: true);
    _sendListPending();
  }

  void updateRemoteMessageStatus(String messageId, String status) {
    final blazeMessage = BlazeMessage(messageId, status: status);
    database.jobsDao.insert(Job(
        jobId: Uuid().v4(),
        action: acknowledgeMessageReceipts,
        priority: 5,
        blazeMessage: jsonEncode(blazeMessage),
        createdAt: DateTime.now(),
        runCount: 0));
  }

  void _sendListPending() {
    _sendGZip(BlazeMessage(Uuid().v4(), action: 'LIST_PENDING_MESSAGES'));
  }

  void _sendGZip(BlazeMessage msg) {
    channel.sink.add(
        GZipEncoder().encode(Uint8List.fromList(jsonEncode(msg).codeUnits)));
  }

  void disconnect() {
    channel?.sink?.close();
  }
}

Future<Map<String, dynamic>> parseBlazeMessage(List<int> message) {
  return compute(_parseBlazeMessageInternal, message);
}

Map<String, dynamic> _parseBlazeMessageInternal(List<int> message) {
  final content = String.fromCharCodes(GZipDecoder().decodeBytes(message));
  final blazeMessage = jsonDecode(content);
  return blazeMessage;
}
