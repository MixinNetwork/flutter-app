
import 'dart:io';

import 'package:flutter/foundation.dart';
import '../blaze/vo/message_result.dart';
import '../constants/constants.dart';
import '../blaze/blaze.dart';
import '../blaze/blaze_message.dart';
import '../blaze/blaze_message_param_session.dart';
import '../blaze/blaze_param.dart';
import '../blaze/blaze_signal_key_message.dart';
import '../blaze/vo/sender_key_status.dart';
import '../blaze/vo/signal_key.dart';
import '../crypto/signal/signal_protocol.dart';
import '../db/database.dart';
import '../utils/string_extension.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import '../db/mixin_database.dart' as db;

class Sender {
  Sender(
      this.signalProtocol,
      this.blaze,
      this.client,
      this.sessionId,
      this.database,
      );

  final SignalProtocol signalProtocol;
  final Blaze blaze;
  final Client client;
  final String sessionId;
  final Database database;

  Future<bool> deliver(BlazeMessage blazeMessage) async {
    final params = blazeMessage.params as BlazeMessageParam;
    final cid = params.conversationId;
    if (cid != null) {
      final checksum = await getCheckSum(cid);
      params.conversationChecksum = checksum;
    }
    final bm = await blaze.sendMessage(blazeMessage);
    if (bm == null) {
      await _sleep(1);
      throw WebSocketException();
    } else if (bm.error != null) {
      if (bm.error?.code == conversationChecksumInvalidError) {
        final cid = (blazeMessage.params as BlazeMessageParam).conversationId;
        if (cid != null) {
          await _syncConversation(cid);
        }
        return false;
      } else if (bm.error?.code == forbidden) {
        return true;
      } else {
        _sleep(1);
        debugPrint('$blazeMessage \n $bm');
        return false;
      }
    } else {
      return true;
    }
  }

  Future<MessageResult> deliverNoThrow(BlazeMessage blazeMessage) async {
    final bm = await blaze.sendMessage(blazeMessage);
    if (bm == null) {
      await _sleep(1);
      return deliverNoThrow(blazeMessage);
    } else if (bm.error != null) {
      if (bm.error?.code == conversationChecksumInvalidError) {
        final cid = (blazeMessage.params as BlazeMessageParam).conversationId;
        if (cid != null) {
          await _syncConversation(cid);
        }
        return MessageResult(false, true);
      } else if (bm.error?.code == forbidden) {
        return MessageResult(true, false);
      } else {
        _sleep(1);
        return deliverNoThrow(blazeMessage);
      }
    } else {
      return MessageResult(true, false);
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

  Future<void> _sleep(int seconds) async => Future.delayed(Duration(seconds: seconds));

  Future checkSessionSenderKey(String conversationId) async {
    final participants = await database.participantSessionDao
        .getNotSendSessionParticipants(conversationId, sessionId);
    if (participants.isEmpty) {
      return;
    }
    final requestSignalKeyUsers = <BlazeMessageParamSession>[];
    final signalKeyMessages = <BlazeSignalKeyMessage>[];
    for (final p in participants) {
      if (!await signalProtocol.containsSession(p.userId,
          deviceId: p.sessionId.getDeviceId())) {
        requestSignalKeyUsers.add(
            BlazeMessageParamSession(userId: p.userId, sessionId: p.sessionId));
      } else {
        final deviceId = p.sessionId.getDeviceId();
        final encryptedResult = await signalProtocol
            .encryptSenderKey(conversationId, p.userId, deviceId: deviceId);
        if (encryptedResult.err) {
          requestSignalKeyUsers.add(BlazeMessageParamSession(
              userId: p.userId, sessionId: p.sessionId));
        } else {
          signalKeyMessages.add(createBlazeSignalKeyMessage(
              p.userId, encryptedResult.result!,
              sessionId: p.sessionId));
        }
      }
    }

    if (requestSignalKeyUsers.isNotEmpty) {
      final blazeMessage = createConsumeSessionSignalKeys(
          createConsumeSignalKeysParam(requestSignalKeyUsers));
      final data = (await signalKeysChannel(blazeMessage))?.data;
      if (data != null) {
        final signalKeys = List<SignalKey>.from(
            (data as List<dynamic>).map((e) => SignalKey.fromJson(e)));
        debugPrint('signalKeys size: ${signalKeys.length}');
        final keys = <BlazeMessageParamSession>[];
        if (signalKeys.isNotEmpty) {
          for (final k in signalKeys) {
            final preKeyBundle = k.createPreKeyBundle();
            await signalProtocol.processSession(k.userId, preKeyBundle);
            final deviceId = preKeyBundle.getDeviceId();
            final encryptedResult = await signalProtocol
                .encryptSenderKey(conversationId, k.userId, deviceId: deviceId);
            signalKeyMessages.add(createBlazeSignalKeyMessage(
                k.userId, encryptedResult.result!,
                sessionId: k.sessionId));
            keys.add(BlazeMessageParamSession(
                userId: k.userId, sessionId: k.sessionId));
          }
        } else {
          debugPrint(
              'No any group signal key from server: ${requestSignalKeyUsers.toString()}');
        }

        final noKeyList = requestSignalKeyUsers.where((e) => !keys.contains(e));
        if (noKeyList.isNotEmpty) {
          final sentSenderKeys = noKeyList
              .map((e) => db.ParticipantSessionData(
            conversationId: conversationId,
            userId: e.userId,
            sessionId: e.sessionId,
          ))
              .toList();
          await database.participantSessionDao.updateList(sentSenderKeys);
        }
      }
    }
    debugPrint('signalKeyMessages size: ${signalKeyMessages.length}');
    if (signalKeyMessages.isEmpty) {
      return;
    }
    final checksum = await getCheckSum(conversationId);
    debugPrint('checksum: $checksum');
    final bm = createSignalKeyMessage(createSignalKeyMessageParam(
        conversationId, signalKeyMessages, checksum));
    final result = await deliverNoThrow(bm);
    debugPrint('result retry:${result.retry}, success: ${result.success}');
    if (result.retry) {
      return checkSessionSenderKey(conversationId);
    }
    if (result.success) {
      final sentSenderKeys = signalKeyMessages
          .map((e) => db.ParticipantSessionData(
          conversationId: conversationId,
          userId: e.recipientId,
          sessionId: e.sessionId!,
          sentToServer: SenderKeyStatus.sent.index))
          .toList();
      await database.participantSessionDao.updateList(sentSenderKeys);
    }
  }

  Future<String> getCheckSum(String conversationId) async {
    final sessions = await database.participantSessionDao
        .getParticipantSessionsByConversationId(conversationId);
    if (sessions.isEmpty) {
      return '';
    } else {
      return generateConversationChecksum(sessions);
    }
  }

  String generateConversationChecksum(List<db.ParticipantSessionData> devices) {
    devices.sort((a, b) => a.sessionId.compareTo(b.sessionId));
    final d = devices.map((e) => e.sessionId).join('');
    return d.md5();
  }

  Future checkConversation(String conversationId) async {
    final conversation =
    await database.conversationDao.getConversationById(conversationId);
    if (conversation == null) {
      return;
    }
    if (conversation.category == ConversationCategory.group) {
      await _syncConversation(conversationId);
    } else {
      await _checkConversationExists(conversation);
    }
  }

  Future _syncConversation(String conversationId) async {
    final res = await client.conversationApi.getConversation(conversationId);
    final conversation = res.data;
    final participants = <db.Participant>[];
    conversation.participants.forEach((c) => participants.add(db.Participant(
        conversationId: conversationId,
        userId: c.userId,
        role: c.role,
        createdAt: c.createdAt!)));
    await database.participantsDao.replaceAll(conversationId, participants);
    if (conversation.participantSessions != null) {
      await _syncParticipantSession(
          conversationId, conversation.participantSessions!);
    }
  }

  Future _syncParticipantSession(
      String conversationId, List<UserSession> data) async {
    await database.participantSessionDao.deleteByStatus(conversationId);
    final remote = <db.ParticipantSessionData>[];
    for (final s in data) {
      remote.add(db.ParticipantSessionData(
          conversationId: conversationId,
          userId: s.userId,
          sessionId: s.sessionId));
    }
    if (remote.isEmpty) {
      await database.participantSessionDao
          .deleteByConversationId(conversationId);
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

  Future _checkConversationExists(db.Conversation conversation) async {
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
          ParticipantRequest(userId: conversation.ownerId!)
        ],
      ),
    );
    await database.conversationDao.updateConversationStatusById(
        conversation.conversationId, ConversationStatus.success);

    final sessionParticipants = response.data.participantSessions;
    if (sessionParticipants != null && sessionParticipants.isNotEmpty) {
      final newParticipantSessions = <db.ParticipantSessionData>[];
      for (final p in sessionParticipants) {
        newParticipantSessions.add(db.ParticipantSessionData(
            conversationId: conversation.conversationId,
            userId: p.userId,
            sessionId: p.sessionId));
      }
      if (newParticipantSessions.isNotEmpty) {
        await database.participantSessionDao
            .replaceAll(conversation.conversationId, newParticipantSessions);
      }
    }
  }
}