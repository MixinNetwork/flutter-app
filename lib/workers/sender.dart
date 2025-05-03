import 'dart:async';
import 'dart:convert';

import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';

import '../blaze/blaze.dart';
import '../blaze/blaze_message.dart';
import '../blaze/blaze_message_param.dart';
import '../blaze/blaze_message_param_session.dart';
import '../blaze/blaze_signal_key_message.dart';
import '../blaze/vo/message_result.dart';
import '../blaze/vo/plain_json_message.dart';
import '../blaze/vo/sender_key_status.dart';
import '../blaze/vo/signal_key.dart';
import '../constants/constants.dart';
import '../crypto/signal/signal_protocol.dart';
import '../db/database.dart';
import '../db/mixin_database.dart' as db;
import '../enum/message_category.dart';
import '../utils/extension/extension.dart';
import '../utils/logger.dart';

class Sender {
  Sender(
    this.signalProtocol,
    this.blaze,
    this.client,
    this.sessionId,
    this.accountId,
    this.database,
  );

  final SignalProtocol signalProtocol;
  final Blaze blaze;
  final Client client;
  final String sessionId;
  final String accountId;
  final Database database;

  Future<MessageResult> deliver(BlazeMessage blazeMessage) async {
    final params = blazeMessage.params as BlazeMessageParam;
    final cid = params.conversationId;
    if (cid != null) {
      final checksum = await getCheckSum(cid);
      params.conversationChecksum = checksum;
    }
    i('deliver blazeMessage: ${blazeMessage.id}');
    final bm = await blaze.sendMessage(blazeMessage);
    if (bm == null) {
      await _sleep(1);
      return deliver(blazeMessage);
    } else if (bm.error != null) {
      w(
        'deliver error code: ${bm.error?.code}, description: ${bm.error?.description}',
      );
      if (bm.error?.code == conversationChecksumInvalidError) {
        final cid = (blazeMessage.params as BlazeMessageParam).conversationId;
        i('checksum error: ${bm.error?.code}  cid:$cid');
        if (cid != null) {
          await syncConversation(cid);
        }
        return MessageResult(false, true, bm.error?.code);
      } else if (bm.error?.code == forbidden) {
        return MessageResult(true, false, bm.error?.code);
      } else if (bm.error?.code == badData) {
        return MessageResult(true, false, bm.error?.code);
      } else {
        await _sleep(1);
        return deliver(blazeMessage);
      }
    } else {
      return MessageResult(true, false, bm.error?.code);
    }
  }

  Future<BlazeMessage?> signalKeysChannel(BlazeMessage blazeMessage) async {
    final bm = await blaze.sendMessage(blazeMessage);
    if (bm == null) {
      await _sleep(1);
      return signalKeysChannel(blazeMessage);
    } else if (bm.error != null) {
      if (bm.error?.code == forbidden) {
        return null;
      } else {
        await _sleep(1);
        return signalKeysChannel(blazeMessage);
      }
    }
    return bm;
  }

  Future<void> _sleep(int seconds) async =>
      Future.delayed(Duration(seconds: seconds));

  Future<bool> checkSignalSession(String recipientId, String sessionId) async {
    final contains = await signalProtocol.containsSession(
      recipientId,
      deviceId: sessionId.getDeviceId(),
    );
    if (!contains) {
      final requestKeys = <BlazeMessageParamSession>[
        BlazeMessageParamSession(userId: recipientId, sessionId: sessionId),
      ];
      final blazeMessage = createConsumeSessionSignalKeys(
        createConsumeSignalKeysParam(requestKeys),
      );
      final data = (await signalKeysChannel(blazeMessage))?.data;
      if (data == null) {
        return false;
      }
      final keys = List<SignalKey>.from(
        (data as List<dynamic>).map(
          (e) => SignalKey.fromJson(e as Map<String, dynamic>),
        ),
      );
      if (keys.isNotEmpty) {
        final preKeyBundle = keys.first.createPreKeyBundle();
        await signalProtocol.processSession(recipientId, preKeyBundle);
      } else {
        return false;
      }
    }
    return true;
  }

  Future checkSessionSenderKey(String conversationId) async {
    final participants =
        await database.participantSessionDao
            .notSendSessionParticipants(conversationId, sessionId)
            .get();
    if (participants.isEmpty) {
      return;
    }
    final requestSignalKeyUsers = <BlazeMessageParamSession>[];
    final signalKeyMessages = <BlazeSignalKeyMessage>[];
    for (final p in participants) {
      if (!await signalProtocol.containsSession(
        p.userId,
        deviceId: p.sessionId.getDeviceId(),
      )) {
        requestSignalKeyUsers.add(
          BlazeMessageParamSession(userId: p.userId, sessionId: p.sessionId),
        );
      } else {
        final deviceId = p.sessionId.getDeviceId();
        final encryptedResult = await signalProtocol.encryptSenderKey(
          conversationId,
          p.userId,
          deviceId: deviceId,
        );
        if (encryptedResult.err) {
          requestSignalKeyUsers.add(
            BlazeMessageParamSession(userId: p.userId, sessionId: p.sessionId),
          );
        } else {
          signalKeyMessages.add(
            createBlazeSignalKeyMessage(
              p.userId,
              encryptedResult.result!,
              sessionId: p.sessionId,
            ),
          );
        }
      }
    }

    if (requestSignalKeyUsers.isNotEmpty) {
      final blazeMessage = createConsumeSessionSignalKeys(
        createConsumeSignalKeysParam(requestSignalKeyUsers),
      );
      final data = (await signalKeysChannel(blazeMessage))?.data;
      if (data != null) {
        final signalKeys = List<SignalKey>.from(
          (data as List<dynamic>).map(
            (e) => SignalKey.fromJson(e as Map<String, dynamic>),
          ),
        );
        i('signalKeys size: ${signalKeys.length}');
        final keys = <BlazeMessageParamSession>[];
        if (signalKeys.isNotEmpty) {
          for (final k in signalKeys) {
            final preKeyBundle = k.createPreKeyBundle();
            await signalProtocol.processSession(k.userId, preKeyBundle);
            final deviceId = preKeyBundle.getDeviceId();
            final encryptedResult = await signalProtocol.encryptSenderKey(
              conversationId,
              k.userId,
              deviceId: deviceId,
            );
            signalKeyMessages.add(
              createBlazeSignalKeyMessage(
                k.userId,
                encryptedResult.result!,
                sessionId: k.sessionId,
              ),
            );
            keys.add(
              BlazeMessageParamSession(
                userId: k.userId,
                sessionId: k.sessionId,
              ),
            );
          }
        } else {
          i('No any group signal key from server: $requestSignalKeyUsers');
        }

        final noKeyList = requestSignalKeyUsers.where((e) => !keys.contains(e));
        if (noKeyList.isNotEmpty) {
          final sentSenderKeys =
              noKeyList
                  .map(
                    (e) => db.ParticipantSessionData(
                      conversationId: conversationId,
                      userId: e.userId,
                      sessionId: e.sessionId,
                    ),
                  )
                  .toList();
          await database.participantSessionDao.updateList(sentSenderKeys);
        }
      }
    }
    i('signalKeyMessages size: ${signalKeyMessages.length}');
    if (signalKeyMessages.isEmpty) {
      return;
    }
    final checksum = await getCheckSum(conversationId);
    i('checksum: $checksum');
    final bm = createSignalKeyMessage(
      createSignalKeyMessageParam(conversationId, signalKeyMessages, checksum),
    );
    final result = await deliver(bm);
    i('result retry:${result.retry}, success: ${result.success}');
    if (result.retry) {
      return checkSessionSenderKey(conversationId);
    }
    if (result.success) {
      final messageIds = signalKeyMessages.map(
        (e) => db.MessagesHistoryData(messageId: e.messageId),
      );
      await database.messageHistoryDao.insertList(messageIds);

      final sentSenderKeys =
          signalKeyMessages
              .map(
                (e) => db.ParticipantSessionData(
                  conversationId: conversationId,
                  userId: e.recipientId,
                  sessionId: e.sessionId!,
                  sentToServer: SenderKeyStatus.sent.index,
                ),
              )
              .toList();
      await database.participantSessionDao.updateList(sentSenderKeys);
    }
  }

  Future<String> getCheckSum(String conversationId) async {
    final sessions = await database.participantSessionDao
        .getParticipantSessionsByConversationId(conversationId);
    return sessions.isEmpty ? '' : generateConversationChecksum(sessions);
  }

  String generateConversationChecksum(List<db.ParticipantSessionData> devices) {
    devices.sort((a, b) => a.sessionId.compareTo(b.sessionId));
    final d = devices.map((e) => e.sessionId).join();
    return d.md5();
  }

  Future checkConversation(String conversationId) async {
    final conversation =
        await database.conversationDao
            .conversationById(conversationId)
            .getSingleOrNull();
    if (conversation == null) {
      return;
    }
    if (conversation.status != ConversationStatus.success) {
      await checkConversationExists(conversation);
    } else {
      await syncConversation(conversationId);
    }
  }

  Future syncConversation(String conversationId) async {
    final res = await client.conversationApi.getConversation(conversationId);
    final conversation = res.data;
    final participants = <db.Participant>[];
    conversation.participants.forEach(
      (c) => participants.add(
        db.Participant(
          conversationId: conversationId,
          userId: c.userId,
          role: c.role,
          createdAt: c.createdAt!,
        ),
      ),
    );
    await database.participantDao.replaceAll(conversationId, participants);
    if (conversation.participantSessions != null) {
      await _syncParticipantSession(
        conversationId,
        conversation.participantSessions!,
      );
    }
  }

  Future _syncParticipantSession(
    String conversationId,
    List<UserSession> data,
  ) async {
    await database.participantSessionDao.deleteByStatus(conversationId);
    final remote = <db.ParticipantSessionData>[];
    for (final s in data) {
      remote.add(
        db.ParticipantSessionData(
          conversationId: conversationId,
          userId: s.userId,
          sessionId: s.sessionId,
          publicKey: s.publicKey,
        ),
      );
    }
    if (remote.isEmpty) {
      await database.participantSessionDao.deleteByConversationId(
        conversationId,
      );
      return;
    }
    final local = await database.participantSessionDao
        .getParticipantSessionsByConversationId(conversationId);
    if (local.isEmpty) {
      await database.participantSessionDao.insertAll(remote);
      return;
    }
    final common = remote.toSet().intersection(local.toSet());
    final remove = <db.ParticipantSessionData>[];
    for (final p in local) {
      if (!common.contains(p)) {
        remove.add(p);
      }
    }
    final add = <db.ParticipantSessionData>[];
    for (final p in remote) {
      if (!common.contains(p)) {
        add.add(p);
      }
    }
    if (remove.isNotEmpty) {
      await database.participantSessionDao.deleteList(remove);
    }
    if (add.isNotEmpty) {
      await database.participantSessionDao.insertAll(add);
    }
  }

  Future<void> checkConversationExists(db.Conversation conversation) async {
    if (conversation.status != ConversationStatus.success) {
      await _createConversation(conversation);
    }
  }

  Future _createConversation(db.Conversation conversation) async {
    final response = await client.conversationApi.createConversation(
      ConversationRequest(
        conversationId: conversation.conversationId,
        category: conversation.category,
        participants: <ParticipantRequest>[
          ParticipantRequest(userId: conversation.ownerId!),
        ],
      ),
    );

    await database.conversationDao.updateConversationStatusById(
      conversation.conversationId,
      ConversationStatus.success,
    );

    final sessionParticipants = response.data.participantSessions;
    if (sessionParticipants != null && sessionParticipants.isNotEmpty) {
      final newParticipantSessions = <db.ParticipantSessionData>[];
      for (final p in sessionParticipants) {
        newParticipantSessions.add(
          db.ParticipantSessionData(
            conversationId: conversation.conversationId,
            userId: p.userId,
            sessionId: p.sessionId,
            publicKey: p.publicKey,
          ),
        );
      }
      if (newParticipantSessions.isNotEmpty) {
        await database.participantSessionDao.replaceAll(
          conversation.conversationId,
          newParticipantSessions,
        );
      }
    }
  }

  Future<bool> sendSenderKey(
    String conversationId,
    String recipientId,
    String sessionId,
  ) async {
    final requestKeys = <BlazeMessageParamSession>[
      BlazeMessageParamSession(userId: recipientId, sessionId: sessionId),
    ];
    final blazeMessage = createConsumeSessionSignalKeys(
      createConsumeSignalKeysParam(requestKeys),
    );
    final data = (await signalKeysChannel(blazeMessage))?.data;
    if (data == null) {
      return false;
    }
    final keys = List<SignalKey>.from(
      (data as List<dynamic>).map(
        (e) => SignalKey.fromJson(e as Map<String, dynamic>),
      ),
    );
    if (keys.isNotEmpty) {
      final preKeyBundle = keys.first.createPreKeyBundle();
      await signalProtocol.processSession(recipientId, preKeyBundle);
    } else {
      await database.participantSessionDao.insert(
        db.ParticipantSessionData(
          conversationId: conversationId,
          userId: recipientId,
          sessionId: sessionId,
        ),
      );
      return false;
    }
    final encryptedResult = await signalProtocol.encryptSenderKey(
      conversationId,
      recipientId,
      deviceId: sessionId.getDeviceId(),
    );
    if (encryptedResult.err) {
      return false;
    }
    final signalKeyMessage = createBlazeSignalKeyMessage(
      recipientId,
      encryptedResult.result!,
      sessionId: sessionId,
    );
    final signalKeyMessages = <BlazeSignalKeyMessage>[signalKeyMessage];
    final checksum = await getCheckSum(conversationId);
    final bm = createSignalKeyMessage(
      createSignalKeyMessageParam(conversationId, signalKeyMessages, checksum),
    );
    final result = await deliver(bm);
    if (result.retry) {
      return sendSenderKey(conversationId, recipientId, sessionId);
    }
    if (result.success) {
      await database.participantSessionDao.insert(
        db.ParticipantSessionData(
          conversationId: conversationId,
          userId: recipientId,
          sessionId: sessionId,
          sentToServer: SenderKeyStatus.sent.index,
        ),
      );
    }
    return result.success;
  }

  Future<void> sendNoKeyMessage(
    String conversationId,
    String recipientId,
  ) async {
    final plainText =
        PlainJsonMessage(
          kNoKey,
          null,
          null,
          null,
          null,
          null,
        ).toJson().toString();
    final encoded = base64Encode(utf8.encode(plainText));
    final blazeParam = BlazeMessageParam(
      conversationId: conversationId,
      recipientId: recipientId,
      messageId: const Uuid().v4(),
      category: MessageCategory.plainJson,
      data: encoded,
      status: MessageStatus.sending.toString(),
    );
    final bm = BlazeMessage(
      id: const Uuid().v4(),
      action: kCreateMessage,
      params: blazeParam,
    );
    unawaited(deliver(bm));
  }

  Future<void> sendProcessSignalKey(
    BlazeMessageData data,
    ProcessSignalKeyAction action, {
    String? participantId,
  }) async {
    if (action == ProcessSignalKeyAction.resendKey) {
      final result = await sendSenderKey(
        data.conversationId,
        data.userId,
        data.sessionId,
      );
      if (!result) {
        await sendNoKeyMessage(data.conversationId, data.userId);
      }
    } else if (action == ProcessSignalKeyAction.removeParticipant) {
      final pid = participantId!;
      await database.transaction(() async {
        await database.participantDao.deleteByCIdAndPId(
          data.conversationId,
          pid,
        );
        await database.participantSessionDao.deleteByCIdAndPId(
          data.conversationId,
          pid,
        );
        await database.participantSessionDao.emptyStatusByConversationId(
          data.conversationId,
        );
      });
      await signalProtocol.clearSenderKey(data.conversationId, accountId);
    } else if (action == ProcessSignalKeyAction.addParticipant) {
      final userIds = <String>[participantId!];
      await refreshSession(data.conversationId, userIds);
    }
  }

  Future<void> refreshSession(
    String conversationId,
    List<String> userIds,
  ) async {
    final response = await client.userApi.getSessions(userIds);
    final list = <db.ParticipantSessionData>[];
    response.data.forEach((e) {
      list.add(
        db.ParticipantSessionData(
          conversationId: conversationId,
          userId: e.userId,
          sessionId: e.sessionId,
          publicKey: e.publicKey,
        ),
      );
    });
    if (list.isNotEmpty) {
      await database.participantSessionDao.insertAll(list);
    }
  }
}

enum ProcessSignalKeyAction { addParticipant, removeParticipant, resendKey }
