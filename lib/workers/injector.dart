import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:very_good_analysis/very_good_analysis.dart';

import '../constants/constants.dart';
import '../db/database.dart';
import '../db/mixin_database.dart' as db;

class Injector {
  Injector(this.accountId, this.database, this.client);

  String accountId;
  Database database;
  Client client;

  final refreshUserIdSet = <String>{};

  Future<void> syncConversion(String? conversationId,
      {bool force = false, bool unWait = false}) async {
    if (conversationId == null || conversationId == systemUser) {
      return;
    }
    final conversation =
        await database.conversationDao.getConversationById(conversationId);
    if (conversation == null || force) {
      if (unWait) {
        unawaited(_refreshConversation(conversationId));
      } else {
        await _refreshConversation(conversationId);
      }
    }
  }

  Future<void> _refreshConversation(String conversationId) async {
    try {
      final response =
          await client.conversationApi.getConversation(conversationId);
      var ownerId = response.data.creatorId;
      if (response.data.category == ConversationCategory.contact) {
        response.data.participants.forEach((item) {
          if (item.userId != accountId) {
            ownerId = item.userId;
          }
        });
      } else if (response.data.category == ConversationCategory.group) {
        await refreshUsers(<String>[ownerId]);
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

      final remote = <db.Participant>[];
      final conversationUserIds = <String>[];
      response.data.participants.forEach((item) {
        remote.add(db.Participant(
            conversationId: conversationId,
            userId: item.userId,
            role: item.role,
            createdAt: item.createdAt ?? DateTime.now()));
        conversationUserIds.add(item.userId);
      });
      unawaited(refreshUsers(conversationUserIds));

      await refreshParticipants(
        response.data.conversationId,
        remote.toList(),
        response.data.participantSessions,
      );
    } catch (e, s) {
      debugPrint('$e');
      debugPrint('$s');
    }
  }

  Future<void> refreshParticipants(String conversationId,
      List<db.Participant> remote, List<UserSession>? userSessions) async {
    await database.participantsDao.replaceAll(conversationId, remote);
    final participantSessions = <db.ParticipantSessionData>[];
    userSessions?.forEach((u) {
      participantSessions.add(db.ParticipantSessionData(
          conversationId: conversationId,
          userId: u.userId,
          sessionId: u.sessionId));
    });
    await database.participantSessionDao
        .replaceAll(conversationId, participantSessions);
  }

  Future<List<db.User>?> refreshUsers(List<String> ids,
      {bool force = false}) async {
    if (ids.isEmpty) {
      return null;
    }
    if (force) {
      return _fetchUsers(ids);
    }

    final existsUserIds = await database.userDao.userIdsByIn(ids).get();
    if (existsUserIds.isEmpty) {
      await _fetchUsers(ids);
    }
    final queryUsers = ids.where((id) => !existsUserIds.contains(id)).toList();
    if (queryUsers.isEmpty) {
      return null;
    }
    return _fetchUsers(ids);
  }

  Future<List<db.User>?> _fetchUsers(List<String> ids) async {
    try {
      final response = await client.userApi.getUsers(ids);
      return insertUpdateUsers(response.data);
    } catch (e, s) {
      debugPrint('$e');
      debugPrint('$s');
    }
  }

  Future<List<db.User>> insertUpdateUsers(List<User> users) async {
    final result = <db.User>[];
    for (final e in users) {
      final user = db.User(
        userId: e.userId,
        identityNumber: e.identityNumber,
        relationship: e.relationship,
        fullName: e.fullName,
        avatarUrl: e.avatarUrl,
        phone: e.phone,
        isVerified: e.isVerified,
        createdAt: e.createdAt,
        muteUntil: DateTime.tryParse(e.muteUntil),
        appId: e.app?.appId,
        biography: e.biography,
        isScam: e.isScam ? 1 : 0,
      );
      result.add(user);

      await database.userDao.insert(user);
      final app = e.app;
      if (app != null) {
        await database.appsDao.insert(
          db.App(
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
            updatedAt: app.updatedAt,
          ),
        );
      }
    }
    return result;
  }

  Future<void> refreshSticker(String stickerId) async {
    try {
      final sticker = (await client.accountApi.getStickerById(stickerId)).data;
      await database.stickerDao.insert(db.Sticker(
        stickerId: sticker.stickerId,
        albumId: sticker.albumId,
        name: sticker.name,
        assetUrl: sticker.assetUrl,
        assetType: sticker.assetType,
        assetWidth: sticker.assetWidth,
        assetHeight: sticker.assetHeight,
        createdAt: sticker.createdAt,
      ));
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> refreshCircle({String? circleId}) async {
    if (circleId == null) {
      final res = await client.circleApi.getCircles();
      res.data.forEach((circle) async {
        await database.circlesDao.insertUpdate(db.Circle(
            circleId: circle.circleId,
            name: circle.name,
            createdAt: circle.createdAt,
            orderedAt: null));
        await handleCircle(circle);
      });
    } else {
      final circle = (await client.circleApi.getCircle(circleId)).data;
      await database.circlesDao.insertUpdate(db.Circle(
          circleId: circle.circleId,
          name: circle.name,
          createdAt: circle.createdAt,
          orderedAt: null));
      await handleCircle(circle);
    }

    if (refreshUserIdSet.isNotEmpty) {
      unawaited(refreshUsers(refreshUserIdSet.toList()));
    }
  }

  Future<void> handleCircle(CircleResponse circle, {int? offset}) async {
    final ccList =
        (await client.circleApi.getCircleConversations(circle.circleId)).data;
    for (final cc in ccList) {
      await database.circleConversationDao.insert(db.CircleConversation(
        conversationId: cc.conversationId,
        circleId: cc.circleId,
        createdAt: cc.createdAt,
      ));
      if (cc.userId != null && !refreshUserIdSet.contains(cc.userId)) {
        final u =
            await database.userDao.findUserById(cc.userId!).getSingleOrNull();
        if (u == null) {
          refreshUserIdSet.add(cc.userId!);
        }
      }
    }
    if (ccList.length >= 500) {
      await handleCircle(circle, offset: offset ?? 0 + 500);
    }
  }
}
