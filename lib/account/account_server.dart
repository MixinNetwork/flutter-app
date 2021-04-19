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
import 'package:flutter_app/constants/constants.dart';
import 'package:flutter_app/crypto/encrypted/encrypted_protocol.dart';
import 'package:flutter_app/crypto/signal/signal_protocol.dart';
import 'package:flutter_app/crypto/uuid/uuid.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/extension/message_category.dart';
import 'package:flutter_app/db/mixin_database.dart' as db;
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/enum/message_status.dart';
import 'package:flutter_app/utils/attachment_util.dart';
import 'package:flutter_app/utils/load_Balancer_utils.dart';
import 'package:flutter_app/utils/stream_extension.dart';
import 'package:flutter_app/workers/decrypt_message.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart';

class AccountServer {
  static String? sid;

  set language(String language) =>
      client.dio.options.headers['Accept-Language'] = language;

  Future<void> initServer(
    String userId,
    String sessionId,
    String identityNumber,
    String privateKey,
  ) async {
    if (sid == sessionId) return;
    sid = sessionId;

    this.userId = userId;
    this.sessionId = sessionId;
    this.identityNumber = identityNumber;
    this.privateKey = PrivateKey(base64Decode(privateKey));

    client = Client(
      userId: userId,
      sessionId: sessionId,
      privateKey: privateKey,
      scp: scp,
    );
    (client.dio.transformer as DefaultTransformer).jsonDecodeCallback =
        LoadBalancerUtils.jsonDecode;

    await _initDatabase(privateKey);
    start();
  }

  Future _initDatabase(String privateKey) async {
    final databaseConnection = await db.createMoorIsolate(identityNumber);
    database = Database(databaseConnection);
    _attachmentUtil =
        await AttachmentUtil.init(client, database.messagesDao, identityNumber);
    _sendMessageHelper = SendMessageHelper(
        database.messagesDao, database.jobsDao, _attachmentUtil);
    blaze = Blaze(userId, sessionId, privateKey, database, client);

    _decryptMessage = DecryptMessage(
        userId, database, client, sessionId, this.privateKey, _attachmentUtil);

    signalProtocol = SignalProtocol(sessionId);
    await signalProtocol.initStore();
  }

  late String userId;
  late String sessionId;
  late String identityNumber;
  late PrivateKey privateKey;

  late Client client;
  late Database database;
  late Blaze blaze;
  late DecryptMessage _decryptMessage;
  late SendMessageHelper _sendMessageHelper;
  late AttachmentUtil _attachmentUtil;

  late SignalProtocol signalProtocol;

  final EncryptedProtocol _encryptedProtocol = EncryptedProtocol();

  void start() {
    blaze.connect();
    database.floodMessagesDao
        .findFloodMessage()
        .where((list) => list.isNotEmpty)
        .asyncMapDrop((list) async {
      for (final message in list) {
        await _decryptMessage.process(message);
      }
      return list;
    }).listen((_) {});

    database.jobsDao
        .findAckJobs()
        .where((jobs) => jobs.isNotEmpty == true)
        .asyncMapDrop(_runAckJob)
        .listen((_) {});

    database.jobsDao
        .findRecallMessageJobs()
        .where((jobs) => jobs.isNotEmpty == true)
        .asyncMapDrop(_runRecallJob)
        .listen((_) {});

    database.jobsDao
        .findSendingJobs()
        .where((jobs) => jobs.isNotEmpty == true)
        .asyncMapDrop(_runSendJob)
        .listen((_) {});

    // database.mock();
  }

  Future<void> _runAckJob(List<db.Job> jobs) async {
    final ack = await Future.wait(
      jobs.where((element) => element.blazeMessage != null).map(
        (e) async {
          final map = await LoadBalancerUtils.jsonDecode(e.blazeMessage!);
          return BlazeAckMessage(
              messageId: map['message_id'], status: map['status']);
        },
      ),
    );

    final jobIds = jobs.map((e) => e.jobId).toList();
    await client.messageApi.acknowledgements(ack);
    await database.jobsDao.deleteJobs(jobIds);
  }

  Future<void> _runRecallJob(List<db.Job> jobs) async {
    jobs.where((element) => element.blazeMessage != null).forEach(
      (e) async {
        final blazeParam = BlazeMessageParam(
            conversationId: e.conversationId,
            messageId: const Uuid().v4(),
            category: MessageCategory.messageRecall,
            data: base64.encode(utf8.encode(e.blazeMessage!)));
        final blazeMessage = BlazeMessage(
            id: const Uuid().v4(), action: createMessage, params: blazeParam);
        blaze.deliver(blazeMessage);
        await database.jobsDao.deleteJobById(e.jobId);
      },
    );
  }

  Future<void> _runSendJob(List<db.Job> jobs) async {
    jobs.where((element) => element.blazeMessage != null).forEach((job) async {
      final message =
          await database.messagesDao.sendingMessage(job.blazeMessage!);
      if (message == null) {
        await database.jobsDao.deleteJobById(job.jobId);
      } else {
        if (message.category.isPlain ||
            message.category == MessageCategory.appCard) {
          var content = message.content;
          if (message.category == MessageCategory.appCard ||
              message.category == MessageCategory.plainPost ||
              message.category == MessageCategory.plainText) {
            content = base64.encode(utf8.encode(content!));
          }
          final blazeMessage = _createBlazeMessage(message, content!);
          blaze.deliver(blazeMessage);
          await database.messagesDao
              .updateMessageStatusById(message.messageId, MessageStatus.sent);
          await database.jobsDao.deleteJobById(job.jobId);
        } else if (message.category.isEncrypted) {
          final conversation = await database.conversationDao
              .getConversationById(message.conversationId);
          if (conversation == null) return;
          final participantSessionKey = await database.participantSessionDao
              .getParticipantSessionKeyWithoutSelf(
                  message.conversationId, userId);
          if (participantSessionKey == null) {
            // todo throw checksum
            return;
          }
          final content = _encryptedProtocol.encryptMessage(
              privateKey,
              utf8.encode(message.content!),
              base64.decode(participantSessionKey.publicKey!),
              participantSessionKey.sessionId);
          final blazeMessage =
              _createBlazeMessage(message, base64Encode(content));
          blaze.deliver(blazeMessage);
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
        id: const Uuid().v4(), action: createMessage, params: blazeParam);
  }

  Future<void> sendTextMessage(String content,
      {String? conversationId,
      String? recipientId,
      String? quoteMessageId,
      bool isPlain = true}) async {
    if (content.isEmpty) return;
    await _sendMessageHelper.sendTextMessage(
        await _initConversation(conversationId, recipientId),
        userId,
        content,
        isPlain,
        quoteMessageId);
  }

  Future<void> sendImageMessage(XFile image,
          {String? conversationId,
          String? recipientId,
          bool isPlain = true,
          String? quoteMessageId}) async =>
      _sendMessageHelper.sendImageMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          image,
          isPlain ? MessageCategory.plainImage : MessageCategory.signalImage,
          quoteMessageId);

  Future<void> sendVideoMessage(XFile video,
          {String? conversationId,
          String? recipientId,
          bool isPlain = true,
          String? quoteMessageId}) async =>
      _sendMessageHelper.sendVideoMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          video,
          isPlain ? MessageCategory.plainVideo : MessageCategory.signalVideo,
          quoteMessageId);

  Future<void> sendAudioMessage(XFile audio,
          {String? conversationId,
          String? recipientId,
          bool isPlain = true,
          String? quoteMessageId}) async =>
      _sendMessageHelper.sendAudioMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          audio,
          isPlain ? MessageCategory.plainAudio : MessageCategory.signalAudio,
          quoteMessageId);

  Future<void> sendDataMessage(XFile file,
          {String? conversationId,
          String? recipientId,
          bool isPlain = true,
          String? quoteMessageId}) async =>
      _sendMessageHelper.sendDataMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          file,
          isPlain ? MessageCategory.plainData : MessageCategory.signalData,
          quoteMessageId);

  Future<void> sendStickerMessage(String stickerId,
          {String? conversationId,
          String? recipientId,
          bool isPlain = true}) async =>
      _sendMessageHelper.sendStickerMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          StickerMessage(stickerId, null, null),
          isPlain
              ? MessageCategory.plainSticker
              : MessageCategory.signalSticker);

  Future<void> sendContactMessage(String shareUserId, String shareUserFullName,
          {String? conversationId,
          String? recipientId,
          bool isPlain = true,
          String? quoteMessageId}) async =>
      _sendMessageHelper.sendContactMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          ContactMessage(shareUserId),
          shareUserFullName,
          isPlain,
          quoteMessageId);

  Future<void> sendRecallMessage(List<String> messageIds,
          {String? conversationId, String? recipientId}) async =>
      _sendMessageHelper.sendRecallMessage(
          await _initConversation(conversationId, recipientId), messageIds);

  Future<void> forwardMessage(String forwardMessageId,
          {String? conversationId,
          String? recipientId,
          bool isPlain = true}) async =>
      _sendMessageHelper.forwardMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          forwardMessageId,
          isPlain);

  void selectConversation(String? conversationId) {
    _decryptMessage.setConversationId(conversationId);
    _markRead(conversationId);
  }

  void _markRead(conversationId) async {
    final ids =
        await database.messagesDao.getUnreadMessageIds(conversationId, userId);
    final status =
        EnumToString.convertToString(MessageStatus.read)!.toUpperCase();
    final now = DateTime.now();
    final jobs = ids
        .map((id) => jsonEncode(BlazeAckMessage(messageId: id, status: status)))
        .map((blazeMessage) => Job(
            jobId: const Uuid().v4(),
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

  Future<void> initSticker() async {
    final res = await client.accountApi.getStickerAlbums();
    if (res.data != null) {
      res.data!.forEach((item) async {
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
  }

  final refreshUserIdSet = <dynamic>{};

  Future<void> initCircles() async {
    refreshUserIdSet.clear();
    final res = await client.circleApi.getCircles();
    if (res.data != null) {
      res.data?.forEach((circle) async {
        await database.circlesDao.insertUpdate(Circle(
            circleId: circle.circleId,
            name: circle.name,
            createdAt: circle.createdAt,
            orderedAt: null));
        await handleCircle(circle);
      });
    }
  }

  Future<void> handleCircle(CircleResponse circle, {int? offset}) async {
    final ccList =
        (await client.circleApi.getCircleConversations(circle.circleId)).data;
    if (ccList == null) {
      return;
    }
    ccList.forEach((cc) async {
      await database.circleConversationDao.insert(db.CircleConversation(
          conversationId: cc.conversationId,
          circleId: cc.circleId,
          createdAt: cc.createdAt));
      if (cc.userId != null && !refreshUserIdSet.contains(cc.userId)) {
        final u =
            await database.userDao.findUserById(cc.userId!).getSingleOrNull();
        if (u == null) {
          refreshUserIdSet.add(cc.userId);
        }
      }
    });
    if (ccList.length >= 500) {
      await handleCircle(circle, offset: offset ?? 0 + 500);
    }
  }

  void _updateStickerAlbums(String albumId) async {
    try {
      final response = await client.accountApi.getStickersByAlbumId(albumId);
      if (response.data != null) {
        final relationships = <StickerRelationship>[];
        response.data!.forEach((sticker) {
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

        await database.stickerRelationshipsDao.insertAll(relationships);
      }
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<String?> downloadAttachment(db.MessageItem message) =>
      _attachmentUtil.downloadAttachment(
        content: message.content!,
        messageId: message.messageId,
        conversationId: message.conversationId,
        category: message.type,
      );

  Future<void> reUploadAttachment(db.MessageItem message) =>
      _sendMessageHelper.reUploadAttachment(
          message.conversationId,
          message.messageId,
          File(message.mediaUrl!),
          message.mediaName,
          message.mediaMimeType!,
          message.mediaSize!,
          message.mediaWidth,
          message.mediaHeight,
          message.thumbImage,
          message.mediaDuration,
          message.mediaWaveform);

  Future<void> addUser(String userId) => _relationship(
      RelationshipRequest(userId: userId, action: RelationshipAction.add));

  Future<void> removeUser(String userId) => _relationship(
      RelationshipRequest(userId: userId, action: RelationshipAction.remove));

  Future<void> blockUser(String userId) => _relationship(
      RelationshipRequest(userId: userId, action: RelationshipAction.block));

  Future<void> unblockUser(String userId) => _relationship(
      RelationshipRequest(userId: userId, action: RelationshipAction.unblock));

  Future<void> _relationship(RelationshipRequest request) async {
    try {
      final response = await client.userApi.relationships(request);
      final user = response.data;
      if (user != null) {
        await database.userDao.insert(db.User(
            userId: user.userId,
            identityNumber: user.identityNumber,
            relationship: user.relationship,
            fullName: user.fullName,
            avatarUrl: user.avatarUrl,
            phone: user.phone,
            isVerified: user.isVerified,
            appId: user.app?.appId,
            biography: user.biography,
            muteUntil: DateTime.tryParse(user.muteUntil),
            isScam: user.isScam ? 1 : 0,
            createdAt: user.createdAt));
      }
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> createGroupConversation(
      String name, List<String> userIds) async {
    final conversationId = const Uuid().v4();

    final response = await client.conversationApi.createConversation(
      ConversationRequest(
        conversationId: conversationId,
        category: ConversationCategory.group,
        name: name.trim(),
        participants:
            userIds.map((e) => ParticipantRequest(userId: e)).toList(),
      ),
    );
    if (response.data != null) {
      final conversation = response.data!;
      await database.conversationDao.insert(
        db.Conversation(
          conversationId: conversation.conversationId,
          ownerId: conversation.creatorId,
          category: conversation.category,
          name: conversation.name,
          iconUrl: conversation.iconUrl,
          announcement: conversation.announcement,
          codeUrl: conversation.codeUrl,
          payType: null,
          createdAt: conversation.createdAt,
          pinTime: null,
          lastMessageId: null,
          lastMessageCreatedAt: null,
          lastReadMessageId: null,
          unseenMessageCount: 0,
          status: ConversationStatus.success,
          draft: null,
          muteUntil: DateTime.tryParse(conversation.muteUntil),
        ),
      );
      for (final participant in conversation.participants) {
        await database.participantsDao.insert(
          db.Participant(
            conversationId: conversation.conversationId,
            userId: participant.userId,
            createdAt: participant.createdAt ?? DateTime.now(),
            role: participant.role,
          ),
        );
      }
      for (final userId in userIds) {
        await addParticipant(conversationId, userId);
      }
    }
  }

  Future<void> exitGroup(String conversationId) =>
      client.conversationApi.exit(conversationId);

  Future<void> addParticipant(
    String conversationId,
    String userId,
  ) async {
    try {
      await client.conversationApi.participants(
          conversationId, 'ADD', [ParticipantRequest(userId: userId)]);
    } catch (e) {
      debugPrint('$e');
      // throw error??
    }
  }

  Future<void> removeParticipant(
    String conversationId,
    String userId,
  ) async {
    try {
      await client.conversationApi.participants(
        conversationId,
        'REMOVE',
        [ParticipantRequest(userId: userId)],
      );
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> updateParticipantRole(
      String conversationId, String userId, ParticipantRole role) async {
    try {
      await client.conversationApi.participants(conversationId, 'REMOVE',
          [ParticipantRequest(userId: userId, role: role)]);
    } catch (e) {
      debugPrint('$e');
    }
  }

  // todo ids not use
  Future<void> createCircle(String name, List<String> ids) async {
    final response =
        await client.circleApi.createCircle(CircleName(name: name));

    if (response.error != null) {
      return await database.circlesDao.insertUpdate(
        db.Circle(
          circleId: response.data!.circleId,
          name: response.data!.name,
          createdAt: response.data!.createdAt,
        ),
      );
    }

    // todo throw error ???
  }

  Future<void> updateCircle(String circleId, String name) async {
    final response =
        await client.circleApi.updateCircle(circleId, CircleName(name: name));
    if (response.error != null) {
      await database.circlesDao.insertUpdate(db.Circle(
          circleId: response.data!.circleId,
          name: response.data!.name,
          createdAt: response.data!.createdAt));
    }

    // todo throw error ???
  }

  Future<String> _initConversation(String? cid, String? recipientId) async {
    if (recipientId != null) {
      final conversationId = generateConversationId(recipientId, userId);
      final conversation =
          await database.conversationDao.getConversationById(conversationId);
      if (conversation == null) {
        await database.conversationDao.insert(db.Conversation(
            conversationId: conversationId,
            category: ConversationCategory.contact,
            createdAt: DateTime.now(),
            ownerId: recipientId,
            status: ConversationStatus.start));
        await database.participantsDao.insert(db.Participant(
            conversationId: conversationId,
            userId: userId,
            createdAt: DateTime.now()));
        await database.participantsDao.insert(db.Participant(
            conversationId: conversationId,
            userId: recipientId,
            createdAt: DateTime.now()));
      }
      return conversationId;
    } else if (cid != null) {
      return cid;
    } else {
      throw Exception('Parameter error');
    }
  }

  Future<void> editContactName(String userId, String name) async {
    // todo
  }

  // id == userId || id = conversationId
  Future<void> editCircleConversation(String circleId, List<String> ids) async {
    // todo
  }

  Future<void> createConversationByUserId(String userId) async {
    // todo
  }

  Future<void> circleRemoveConversation(
      String circleId, String conversationId) async {
    final response =
        await client.circleApi.updateCircleConversations(circleId, [
      CircleConversationRequest(
          action: CircleConversationAction.REMOVE,
          conversationId: conversationId,
          userId: userId)
    ]);
    if (response.error != null) {
      await database.circleConversationDao
          .deleteByIds(conversationId, circleId);
    } else {}
  }

  Future<void> circleAddConversation(
      String circleId, String conversationId, String? userId) async {
    final response =
        await client.circleApi.updateCircleConversations(circleId, [
      CircleConversationRequest(
          action: CircleConversationAction.ADD,
          conversationId: conversationId,
          userId: userId)
    ]);
    if (response.error != null) {
      final list = response.data;
      for (final cc in list!) {
        await database.circleConversationDao.insert(db.CircleConversation(
            conversationId: cc.conversationId,
            circleId: cc.circleId,
            createdAt: cc.createdAt));
        if (cc.userId != null && !refreshUserIdSet.contains(cc.userId)) {
          final u =
              await database.userDao.findUserById(cc.userId!).getSingleOrNull();
          if (u == null) {
            refreshUserIdSet.add(cc.userId);
          }
        }
      }
    } else {}
  }

  Future<void> deleteCircle(String circleId) async {
    final response = await client.circleApi.deleteCircle(circleId);
    if (response.error != null) {
      await database.circlesDao.deleteCircleById(circleId);
      await database.circleConversationDao.deleteByCircleId(circleId);
      // todo select current circle
    } else {
      // todo handle error
    }
  }

  Future<void> report(String userId) async {
    final response = await client.userApi.report(
        RelationshipRequest(userId: userId, action: RelationshipAction.block));
    if (response.error == null) {
      final user = response.data!;
      await database.userDao.insert(db.User(
        userId: user.userId,
        identityNumber: user.identityNumber,
        relationship: user.relationship,
        fullName: user.fullName,
        avatarUrl: user.avatarUrl,
        phone: user.phone,
        isVerified: user.isVerified,
        createdAt: user.createdAt,
        muteUntil: DateTime.tryParse(user.muteUntil),
        hasPin: user.hasPin == true ? 1 : 0,
        appId: user.appId,
        biography: user.biography,
        isScam: user.isScam ? 1 : 0,
      ));
    } else {
      // todo handle error
    }
  }

  Future<void> unMuteUser(String userId) async {
    await _mute(0, userId: userId);
  }

  Future<void> muteUser(String userId, int duration) async {
    await _mute(duration, userId: userId);
  }

  Future<void> unMuteGroup(String conversationId) async {
    await _mute(0, conversationId: conversationId);
  }

  Future<void> muteGroup(String conversationId, int duration) async {
    await _mute(duration, conversationId: conversationId);
  }

  Future<void> _mute(int duration,
      {String? conversationId, String? userId}) async {
    MixinResponse<ConversationResponse> response;
    if (conversationId != null) {
      response = await client.conversationApi.mute(
          conversationId,
          ConversationRequest(
              conversationId: conversationId,
              category: ConversationCategory.group,
              duration: duration));
    } else if (userId != null) {
      final cid = generateConversationId(userId, this.userId);
      response = await client.conversationApi.mute(
          cid,
          ConversationRequest(
              conversationId: cid,
              category: ConversationCategory.contact,
              duration: duration,
              participants: [ParticipantRequest(userId: userId)]));
    } else {
      throw Exception('Parameter error');
    }
    if (response.error != null) {
      // handle error
    }
  }

  Future<void> editGroupAnnouncement(
      String conversationId, String announcement) async {
    final response = await client.conversationApi.update(
        conversationId,
        ConversationRequest(
            conversationId: conversationId, announcement: announcement));
    if (response.error != null) {
      // handle error
    }
  }

  Future<void> unpin(String conversationId) async {
    // todo
  }

  Future<void> pin(String conversationId) async {
    // todo
  }
}
