import 'package:flutter/widgets.dart';
import 'package:flutter_app/constans.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/mixin_database.dart' as MixinDatabase;
import 'package:flutter_app/mixin_client.dart';
import 'package:mixin_bot_sdk_dart/src/vo/participant_request.dart';

class BaseWorker {
  // print(conversationId);
  BaseWorker(this.selfId);

  String selfId;

  void syncConversion(String conversationId) async {
    if (conversationId == null || conversationId == systemUser) {
      return;
    }
    final result =
        await Database().conversationDao.getConversationById(conversationId);
    if (result.isEmpty) {
      final response = await MixinClient()
          .client
          .conversationApi
          .getConversation(conversationId);
      if (response.data != null) {
        var ownerId = response.data.creatorId;
        if (response.data.category == ConversationCategory.contact) {
          response.data.participants.forEach((item) {
            if (item.userId != selfId) {
              ownerId = item.userId;
            }
          });
        }

        await Database().conversationDao.insert(MixinDatabase.Conversation(
            conversationId: response.data.conversationId,
            ownerId: ownerId,
            category: response.data.category,
            name: response.data.name,
            announcement: response.data.announcement,
            createdAt: response.data.createdAt,
            status: ConversationStatus.success.index,
            muteUntil: response.data.muteUntil));
        refreshParticipants(
            response.data.conversationId, response.data.participants);
      }
    }
  }

  void refreshParticipants(
      String conversationId, List<ParticipantRequest> participants) async {
    final local =
        await Database().participantsDao.getParticipants(conversationId);
    final localIds = local.map((e) => e.userId);
    final online = <MixinDatabase.Participant>[];
    participants.forEach((item) => {
          online.add(MixinDatabase.Participant(
              conversationId: conversationId,
              userId: item.userId,
              role: item.role,
              createdAt: item.createdAt))
        });
    final add = online.where((item) => !localIds.any((e) => e == item.userId));
    final remove =
        localIds.where((item) => !online.any((e) => e.userId == item));
    if (add.isNotEmpty) {
      Database().participantsDao.insertAll(add.toList());
      fetchUsers(add.map((e) => e.userId).toList());
    }
    if (remove.isNotEmpty) {
      //Todo remove participants
    }
  }

  void fetchUsers(List<String> ids) async {
    final response = await MixinClient().client.userApi.getUsers(ids);
    if (response.data != null && response.data.isNotEmpty) {
      Database().userDao.insertAll(response.data
          .map((e) => MixinDatabase.User(
                userId: e.userId,
                identityNumber: e.identityNumber,
                relationship: e.relationship,
                fullName: e.fullName,
                avatarUrl: e.avatarUrl,
                phone: e.phone,
                isVerified: e.isVerified ? 1 : 0,
                createdAt: e.createdAt,
                muteUntil: e.muteUntil,
                appId: e.appId,
                biography: e.biography,
                isScam: e.isScam ? 1 : 0,
              ))
          .toList());
    } else {
      debugPrint(response.error.toJson().toString());
    }
  }
}
