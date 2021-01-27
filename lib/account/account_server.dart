import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_app/account/send_message_helper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_app/blaze/blaze.dart';
import 'package:flutter_app/blaze/blaze_message.dart';
import 'package:flutter_app/blaze/blaze_param.dart';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/mixin_database.dart' as db;
import 'package:flutter_app/enum/message_status.dart';
import 'package:flutter_app/utils/load_Balancer_utils.dart';
import 'package:flutter_app/workers/decrypt_message.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:flutter_app/utils/stream_extension.dart';
import 'package:uuid/uuid.dart';

class AccountServer {
  static String sid;

  Future<void> initServer(
    String userId,
    String sessionId,
    String identityNumber,
    String privateKey,
  ) async {
    assert(userId != null);
    assert(sessionId != null);
    assert(identityNumber != null);
    assert(privateKey != null);
    this.userId = userId;
    this.sessionId = sessionId;
    this.identityNumber = identityNumber;
    this.privateKey = privateKey;

    client = Client();
    (client.dio.transformer as DefaultTransformer).jsonDecodeCallback =
        LoadBalancerUtils.jsonDecode;
    client.initMixin(userId, sessionId, privateKey, scp);

    await _initDatabase();
    start();
  }

  Future _initDatabase() async {
    final databaseConnection = await db.createMoorIsolate(identityNumber);
    database = Database(databaseConnection);
    _sendMessageHelper =
        SendMessageHelper(database.messagesDao, database.jobsDao);
    blaze = Blaze(userId, sessionId, privateKey, database, client);
    _decryptMessage = DecryptMessage(userId, database, client);
  }

  String userId;
  String sessionId;
  String identityNumber;
  String privateKey;

  Client client;
  Database database;
  Blaze blaze;
  DecryptMessage _decryptMessage;
  SendMessageHelper _sendMessageHelper;

  void start() {
    // todo remove, development only
    if (sid == sessionId) {
      return;
    }

    sid = sessionId;
    blaze.connect();
    database.floodMessagesDao.findFloodMessage().listen((list) {
      if (list?.isNotEmpty == true) {
        for (final message in list) {
          _decryptMessage.process(message);
        }
      }
    });
    database.jobsDao
        .findAckJobs()
        .where((jobs) => jobs?.isNotEmpty == true)
        .asyncMapDrop(runAckJob)
        .listen((_) {});

    database.jobsDao
        .findSendingJobs()
        .where((jobs) => jobs?.isNotEmpty == true)
        .asyncMapDrop(runSendJob)
        .listen((_) {});

    _initSticker();
    // database.mock();
  }

  Future<void> runAckJob(List<db.Job> jobs) async {
    final ack = await Future.wait(jobs.map((e) async {
      final map = await LoadBalancerUtils.jsonDecode(e.blazeMessage);
      return BlazeAckMessage(
          messageId: map['message_id'], status: map['status']);
    }));

    final jobIds = jobs.map((e) => e.jobId).toList();
    await client.messageApi.acknowledgements(ack);
    await database.jobsDao.deleteJobs(jobIds);
  }

  Future<void> runSendJob(List<db.Job> jobs) async {
    jobs.forEach((job) async {
      final message =
          await database.messagesDao.sendingMessage(job.blazeMessage);
      if (message == null) {
        await database.jobsDao.deleteJobById(job.jobId);
      } else {
        if (message.category.startsWith('PLAIN_') ||
            message.category == MessageCategory.appCard) {
          var content = message.content;
          if (message.category == MessageCategory.appCard ||
              message.category == MessageCategory.plainPost ||
              message.category == MessageCategory.plainText) {
            content = base64.encode(utf8.encode(content));
          }
          final blazeMessage = _createBlazeMessage(message, content);
          blaze.deliver(message, blazeMessage);
          await database.messagesDao
              .updateMessageStatusById(message.messageId, MessageStatus.sent);
          await database.jobsDao.deleteJobById(job.jobId);
        } else {
          // todo send signal
        }
      }
    });
  }

  BlazeMessage _createBlazeMessage(db.SendingMessage message, String data) {
    final blazeParam = BlazeMessageParam(
        conversationId: message.conversationId,
        messageId: message.messageId,
        category: message.category,
        data: data,
        quoteMessageId: message.quoteMessageId);

    return BlazeMessage(
        id: Uuid().v4(), action: createMessage, params: blazeParam);
  }

  void sendTextMessage(
    String conversationId,
    String content, [
    bool isPlain = true,
  ]) {
    assert(_decryptMessage != null);
    if (content == null || content.isEmpty) return;
    _sendMessageHelper.sendTextMessage(
        conversationId, userId, content, isPlain);
  }

  void selectConversation(String conversationId) {
    _decryptMessage.setConversationId(conversationId);
    _markRead(conversationId);
  }

  void _markRead(conversationId) {
    // todo mark read by conversation id
  }

  void stop() {
    blaze.disconnect();
    database.dispose();
  }

  void release() {
    // todo release resource
  }

  void _initSticker() {
    client.accountApi.getStickerAlbums().then((res) {
      if (res.data != null) {
        res.data.forEach((item) async {
          await database.stickerAlbumsDao.insert(db.StickerAlbum(
              albumId: item.albumId,
              name: item.name,
              iconUrl: item.iconUrl,
              createdAt: item.createdAt,
              updateAt: item.updateAt,
              userId: item.userId,
              category: item.category,
              description: item.description));
          _updateStickerAlbums(item.albumId);
        });
      }
    }).catchError((e) => debugPrint(e));
  }

  void _updateStickerAlbums(String alumId) {
    client.accountApi.getStickersByAlbumId(alumId).then((res) {
      if (res.data != null) {
        res.data.forEach((sticker) {
          database.stickerDao.insert(db.Sticker(
              stickerId: sticker.stickerId,
              name: sticker.name,
              assetUrl: sticker.assetUrl,
              assetType: sticker.assetType,
              assetWidth: sticker.assetWidth,
              assetHeight: sticker.assetHeight,
              createdAt: sticker.createdAt));
        });
      }
    }).catchError((e) => debugPrint(e));
  }
}
