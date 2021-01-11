import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/constans.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/workers/base_worker.dart';
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
    channel = IOWebSocketChannel.connect(
        'wss://blaze.mixin.one?access_token=$token',
        protocols: ['Mixin-Blaze-1']);
    channel.stream.listen((message) async {
      final blazeMessage = await _parseBlazeMessage(message);
      final data = blazeMessage['data'];
      if (blazeMessage['action'] == 'ACKNOWLEDGE_MESSAGE_RECEIPT') {
        // makeMessageStatus
      } else if (blazeMessage['action'] == 'CREATE_MESSAGE') {
        if (data['user_id'] == selfId && data['category'] == '') {
          // makeMessageStatus
        } else {
          await database.floodMessagesDao
              .insert(FloodMessage(
                  messageId: data['message_id'],
                  data: data.toString(),
                  createdAt: data['created_at']))
              .then((value) {
            // todo delete
            updateRemoteMessageStatus(data['message_id'], 'DELIVERED');
          });
          try {
            // todo delete
            BaseWorker(selfId, database, client)
                .syncConversion(data['conversation_id']);
          } catch (e) {
            debugPrint(e);
          }
        }
      } else {
        debugPrint(data.toString());
        // updateRemoteMessageStatus(data['message_id'], 'DELIVERED');
      }
    }, onError: (error) {
      debugPrint('onError');
    }, onDone: () {
      debugPrint('onDone');
    }, cancelOnError: true);

    _sendListPending();
  }

  Future<Map<String, dynamic>> _parseBlazeMessage(List<int> message) {
    return compute(_parseBlazeMessageInternal, message);
  }

  Map<String, dynamic> _parseBlazeMessageInternal(List<int> message) {
    final content = String.fromCharCodes(GZipDecoder().decodeBytes(message));
    final blazeMessage = jsonDecode(content);
    return blazeMessage;
  }

  void updateRemoteMessageStatus(String messageId, String status) {
    // todo save jobs table
    _sendGZip(BlazeMessage(messageId, status: status));
  }

  void _sendListPending() {
    _sendGZip(BlazeMessage(Uuid().v4(), action: 'LIST_PENDING_MESSAGES'));
  }

  void _sendGZip(BlazeMessage msg) {
    channel.sink.add(
        GZipEncoder().encode(Uint8List.fromList(jsonEncode(msg).codeUnits)));
  }

  void disconnect() {
    // Todo disconnect
  }
}
