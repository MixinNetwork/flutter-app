import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/auth_cubit.dart';
import 'package:flutter_app/workers/base_worker.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';

import 'blaze_message.dart';

class Blaze {
  factory Blaze() {
    return _singleton;
  }

  Blaze._internal();

  static final Blaze _singleton = Blaze._internal();

  IOWebSocketChannel channel;
  String selfId;
  void connect(AuthCubit authCubit) {
    final account = authCubit.state.account;
    final privateKey = authCubit.state.privateKey;
    selfId = account.userId;
    final token = signAuthTokenWithEdDSA(
        account.userId,
        account.sessionId,
        privateKey,
        'PROFILE:READ PROFILE:WRITE PHONE:READ PHONE:WRITE CONTACTS:READ CONTACTS:WRITE MESSAGES:READ MESSAGES:WRITE ASSETS:READ SNAPSHOTS:READ CIRCLES:READ CIRCLES:WRITE',
        'GET',
        '/',
        '');
    _connect(token);
  }

  void _connect(String token) {
    channel = IOWebSocketChannel.connect(
        'wss://blaze.mixin.one?access_token=$token',
        protocols: ['Mixin-Blaze-1']);
    channel.stream.listen((message) {
      final content = String.fromCharCodes(GZipDecoder().decodeBytes(message));
      final blazeMessage = jsonDecode(content);

      final data = blazeMessage['data'];
      if (blazeMessage['action'] == 'ACKNOWLEDGE_MESSAGE_RECEIPT') {
        // makeMessageStatus
      } else if (blazeMessage['action'] == 'CREATE_MESSAGE') {
        if (data['user_id'] == selfId && data['category'] == '') {
          // makeMessageStatus
        } else {
          Database()
              .floodMessagesDao
              .insert(FloodMessage(
                  messageId: data['message_id'],
                  data: data.toString(),
                  createdAt: data['created_at']))
              .then((value) {
            // todo delete
            updateRemoteMessageStatus(data['message_id'], 'DELIVERED');
          });
          try {
            BaseWorker(selfId).syncConversion(data['conversation_id']);
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
}
