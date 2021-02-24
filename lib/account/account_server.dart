import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/account/send_message_helper.dart';
import 'package:flutter_app/blaze/blaze.dart';
import 'package:flutter_app/blaze/blaze_message.dart';
import 'package:flutter_app/blaze/blaze_param.dart';
import 'package:flutter_app/blaze/vo/contact_message.dart';
import 'package:flutter_app/blaze/vo/sticker_message.dart';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/extension/message_category.dart';
import 'package:flutter_app/db/mixin_database.dart' as db;
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/enum/message_status.dart';
import 'package:flutter_app/utils/attachment_util.dart';
import 'package:flutter_app/utils/enum_to_string.dart';
import 'package:flutter_app/utils/load_Balancer_utils.dart';
import 'package:flutter_app/utils/stream_extension.dart';
import 'package:flutter_app/workers/decrypt_message.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';

class AccountServer {
  static String sid;

  set language(String language) =>
      client.dio.options.headers['Accept-Language'] = language;

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
    _attachmentUtil = await AttachmentUtil.init(client, database.messagesDao, identityNumber);
    _sendMessageHelper = SendMessageHelper(
        database.messagesDao, database.jobsDao, _attachmentUtil);
    blaze = Blaze(userId, sessionId, privateKey, database, client);
    _decryptMessage = DecryptMessage(userId, database, client, _attachmentUtil);
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
  AttachmentUtil _attachmentUtil;

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
        if (message.category.isPlain ||
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

  void sendImageMessage(
    String conversationId,
    File image, [
    bool isPlain = true,
  ]) {
    _sendAttachmentMessage(conversationId, image,
        isPlain ? MessageCategory.plainImage : MessageCategory.signalImage);
  }

  void sendVideoMessage(
    String conversationId,
    File video, [
    bool isPlain = true,
  ]) {
    _sendAttachmentMessage(conversationId, video,
        isPlain ? MessageCategory.plainVideo : MessageCategory.signalVideo);
  }

  void sendAudioMessage(
    String conversationId,
    File audio, [
    bool isPlain = true,
  ]) {
    _sendAttachmentMessage(conversationId, audio,
        isPlain ? MessageCategory.plainAudio : MessageCategory.signalAudio);
  }

  void sendDataMessage(
    String conversationId,
    File file, [
    bool isPlain = true,
  ]) {
    _sendAttachmentMessage(conversationId, file,
        isPlain ? MessageCategory.plainData : MessageCategory.signalData);
  }

  void sendAttachment(String conversationId, XFile file,
      [bool isPlain = true]) async {
    _sendMessageHelper.sendDataMessage(conversationId, userId, file, isPlain);
  }

  Future<void> _sendAttachmentMessage(
      String conversationId, File file, MessageCategory category) async {
    if (category.isImage) {
      // todo
      // final imageInfo = await getImageInfo(Image.file(file).image);
      // final width = imageInfo.image.width;
      // final height = imageInfo.image.height;
    } else if (category.isVideo) {
      // todo get width height
    } else if (category.isAudio) {
      // todo get width height
    } else {
      // todo get mime type
    }
  }

  Future<void> sendStickerMessage(
    String conversationId,
    String stickerId, {
    bool isPlain = true,
  }) =>
      _sendMessageHelper.sendStickerMessage(
        conversationId,
        userId,
        StickerMessage(stickerId, null, null),
        isPlain: isPlain,
      );

  void sendContactMessage(
      String conversationId, String shareUserId, String shareUserFullName,
      [bool isPlain = true]) {
    _sendMessageHelper.sendContactMessage(conversationId, userId,
        ContactMessage(shareUserId), shareUserFullName, isPlain);
  }

  void selectConversation(String conversationId) {
    _decryptMessage.setConversationId(conversationId);
    _markRead(conversationId);
  }

  void _markRead(conversationId) async {
    final ids =
        await database.messagesDao.getUnreadMessageIds(conversationId, userId);
    final status = EnumToString.convertToString(MessageStatus.read);
    final now = DateTime.now();
    final jobs = ids
        .map((id) => jsonEncode(BlazeAckMessage(messageId: id, status: status)))
        .map((blazeMessage) => Job(
            jobId: Uuid().v4(),
            action: acknowledgeMessageReceipts,
            priority: 5,
            blazeMessage: blazeMessage,
            createdAt: now,
            runCount: 0))
        .toList();
    database.jobsDao.insertAll(jobs);
  }

  Future<void> stop() async {
    await Future.wait([
      blaze.disconnect(),
      database.dispose(),
    ]);
  }

  void release() {
    // todo release resource
  }

  void initSticker() {
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

  void _updateStickerAlbums(String albumId) {
    client.accountApi.getStickersByAlbumId(albumId).then((res) {
      if (res.data != null) {
        final relationships = <StickerRelationship>[];
        res.data.forEach((sticker) {
          relationships.add(StickerRelationship(
              albumId: albumId, stickerId: sticker.stickerId));
          database.stickerDao.insert(db.Sticker(
            stickerId: sticker.stickerId,
            albumId: albumId,
            name: sticker.name,
            assetUrl: sticker.assetUrl,
            assetType: sticker.assetType,
            assetWidth: sticker.assetWidth,
            assetHeight: sticker.assetHeight,
            createdAt: sticker.createdAt,
          ));
        });

        database.stickerRelationshipsDao.insertAll(relationships);
      }
    }).catchError((e) => debugPrint(e));
  }
}
