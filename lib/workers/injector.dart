import 'package:flutter/widgets.dart';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/mixin_database.dart' as db;
import 'package:flutter_app/enum/conversation_status.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

class Injector {
  Injector(this.selfId, this.database, this.client);

  String selfId;
  Database database;
  Client client;

  void syncConversion(String conversationId) async {
    if (conversationId == null || conversationId == systemUser) {
      return;
    }
    final conversation =
        await database.conversationDao.getConversationById(conversationId);
    if (conversation == null) {
      final response =
          await client.conversationApi.getConversation(conversationId);
      if (response.data != null) {
        var ownerId = response.data.creatorId;
        if (response.data.category == ConversationCategory.contact) {
          response.data.participants.forEach((item) {
            if (item.userId != selfId) {
              ownerId = item.userId;
            }
          });
        }

        await database.conversationDao.insert(
          db.Conversation(
            conversationId: response.data.conversationId,
            ownerId: ownerId,
            category: response.data.category,
            name: response.data.name,
            announcement: response.data.announcement,
            createdAt: response.data.createdAt,
            status: ConversationStatus.success,
            muteUntil: DateTime.parse(response.data.muteUntil),
          ),
        );
        refreshParticipants(
            response.data.conversationId, response.data.participants);
      }
    }
  }

  void refreshParticipants(String conversationId, participants) async {
    final local =
        await database.participantsDao.getParticipants(conversationId);
    final localIds = local.map((e) => e.userId);
    final online = <db.Participant>[];
    participants.forEach((item) => {
          online.add(db.Participant(
              conversationId: conversationId,
              userId: item.userId,
              role: item.role,
              createdAt: item.createdAt))
        });
    final add = online.where((item) => !localIds.any((e) => e == item.userId));
    final remove =
        local.where((item) => !online.any((e) => e.userId == item.userId));
    if (add.isNotEmpty) {
      database.participantsDao.insertAll(add.toList());
      fetchUsers(add.map((e) => e.userId).toList());
    }
    if (remove.isNotEmpty) {
      // database.participantsDao.deleteAll(remove);
    }
  }

  void fetchUsers(List<String> ids) async {
    final response = await client.userApi.getUsers(ids);
    if (response.data != null && response.data.isNotEmpty) {
      database.userDao.insertAll(response.data
          .map((e) => db.User(
                userId: e.userId,
                identityNumber: e.identityNumber,
                relationship: e.relationship,
                fullName: e.fullName,
                avatarUrl: e.avatarUrl,
                phone: e.phone,
                isVerified: e.isVerified ? 1 : 0,
                createdAt: e.createdAt,
                muteUntil: DateTime.tryParse(e.muteUntil),
                appId: e.appId,
                biography: e.biography,
                isScam: e.isScam ? 1 : 0,
              ))
          .toList());
    } else {
      debugPrint(response.error.toJson().toString());
    }
  }

  Future<db.User> syncUser(userId) async {
    var user = await database.userDao.findUserById(userId);
    if (user == null) {
      final response = await client.userApi.getUserById(userId);
      if (response.data != null) {
        final result = response.data;
        user = db.User(
            userId: result.userId,
            identityNumber: result.identityNumber,
            relationship: result.relationship,
            fullName: result.fullName,
            avatarUrl: result.avatarUrl,
            phone: result.phone,
            isVerified: result.isVerified ? 1 : 0,
            appId: result.app?.appId,
            biography: result.biography,
            muteUntil: DateTime.tryParse(result.muteUntil),
            isScam: result.isScam ? 1 : 0,
            createdAt: result.createdAt);
        await database.userDao.insert(user);
        final app = result.app;
        if (app != null) {
          await database.appsDao.insert(db.App(
              appId: app.appId,
              appNumber: app.appNumber,
              homeUri: app.homeUri,
              redirectUri: app.redirectUri,
              name: app.name,
              iconUrl: app.iconUrl,
              category: app.category,
              description: app.description,
              appSecret: app.category,
              capabilities: app.capabilites.toString(),
              creatorId: app.creatorId,
              resourcePatterns: app.resourcePatterns.toString(),
              updatedAt: app.updatedAt));
        }
      }
    }
    return user;
  }

  void refreshSticker(String stickerId) {
    client.accountApi
        .getStickerById(stickerId)
        .then((value){
          final sticker = value.data;
          if(sticker!=null){
            database.stickerDao.insert(db.Sticker(
                stickerId: sticker.stickerId,
                name: sticker.name,
                assetUrl: sticker.assetUrl,
              assetType: sticker.assetType,
              assetWidth: sticker.assetWidth,
              assetHeight: sticker.assetHeight,
              createdAt: sticker.createdAt
            ));
          }
    }).catchError((e) => debugPrint(e));
  }
}
