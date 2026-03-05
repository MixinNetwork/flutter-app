import 'dart:async';

import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../constants/constants.dart';
import '../db/dao/user_dao.dart';
import '../db/database.dart';
import '../db/database_event_bus.dart';
import '../db/mixin_database.dart' as db;
import '../runtime/db_write/method.dart';
import '../runtime/db_write/payload.dart';
import '../utils/extension/extension.dart';
import '../utils/logger.dart';

class Injector {
  Injector(
    this.accountId,
    this.database,
    this.client, {
    required Future<void> Function(DbWriteMethod method, {Object? payload})
    requestDbWrite,
  }) : _requestDbWrite = requestDbWrite;

  String accountId;
  Database database;
  Client client;
  final Future<void> Function(DbWriteMethod method, {Object? payload})
  _requestDbWrite;

  final refreshUserIdSet = <String>{};

  Future<void> syncConversion(
    String? conversationId, {
    bool force = false,
    bool unWait = false,
  }) async {
    if (conversationId == null ||
        conversationId == systemUser ||
        conversationId == accountId) {
      return;
    }
    final conversation = await database.conversationDao
        .conversationById(conversationId)
        .getSingleOrNull();
    if (conversation == null || force) {
      if (unWait) {
        unawaited(refreshConversation(conversationId));
      } else {
        await refreshConversation(conversationId);
      }
    }
  }

  Future<void> refreshConversation(
    String conversationId, {
    bool checkCurrentUserExist = false,
  }) async {
    try {
      final response = await client.conversationApi.getConversation(
        conversationId,
      );
      var ownerId = response.data.creatorId;
      if (response.data.category == ConversationCategory.contact) {
        final legal = response.data.participants.any(
          (item) => item.userId == accountId,
        );
        if (!legal) throw Exception('Conversation is not legal');

        response.data.participants.forEach((item) {
          if (item.userId != accountId) {
            ownerId = item.userId;
          }
        });
      } else if (response.data.category == ConversationCategory.group) {
        if (checkCurrentUserExist) {
          final existed = response.data.participants.any(
            (item) => item.userId == accountId,
          );
          if (!existed) {
            throw Exception('The group is not include current user');
          }
        }
        await refreshUsers(<String>[ownerId]);
      }
      final status =
          response.data.participants.firstWhereOrNull(
                (element) => element.userId == accountId,
              ) !=
              null
          ? ConversationStatus.success
          : ConversationStatus.quit;

      await _upsertConversation(
        db.Conversation(
          conversationId: response.data.conversationId,
          ownerId: ownerId,
          category: response.data.category,
          name: response.data.name,
          announcement: response.data.announcement,
          createdAt: response.data.createdAt,
          status: status,
          muteUntil: DateTime.parse(response.data.muteUntil),
          codeUrl: response.data.codeUrl,
          expireIn: response.data.expireIn,
        ),
      );

      final remote = <db.Participant>[];
      final conversationUserIds = <String>[];
      response.data.participants.forEach((item) {
        remote.add(
          db.Participant(
            conversationId: conversationId,
            userId: item.userId,
            role: item.role,
            createdAt: item.createdAt ?? DateTime.now(),
          ),
        );
        conversationUserIds.add(item.userId);
      });
      unawaited(refreshUsers(conversationUserIds));

      await refreshParticipants(
        response.data.conversationId,
        remote.toList(),
        response.data.participantSessions,
      );
    } catch (e, s) {
      w('refreshConversation error $e, stack: $s');
    }
  }

  Future<void> refreshParticipants(
    String conversationId,
    List<db.Participant> remote,
    List<UserSession>? userSessions,
  ) async {
    await _replaceParticipants(conversationId, remote);
    final participantSessions = <db.ParticipantSessionData>[];
    userSessions?.forEach((u) {
      participantSessions.add(
        db.ParticipantSessionData(
          conversationId: conversationId,
          userId: u.userId,
          sessionId: u.sessionId,
          publicKey: u.publicKey,
        ),
      );
    });
    await _replaceParticipantSessions(conversationId, participantSessions);
  }

  Future<List<db.User>?> refreshUsers(
    List<String> ids, {
    bool force = false,
  }) async {
    if (ids.isEmpty) {
      return null;
    }
    if (force) {
      return _fetchUsers(ids);
    }

    final existsUsers = await database.userDao.usersByIn(ids).get();
    if (existsUsers.isEmpty) {
      return _fetchUsers(ids);
    }

    if (existsUsers.length == ids.length) {
      return existsUsers;
    }

    final existsUsersIds = existsUsers.map((e) => e.userId).toSet();
    final queryUsers = ids.where((id) => !existsUsersIds.contains(id)).toList();
    if (queryUsers.isEmpty) return existsUsers;

    return [...existsUsers, ...?await _fetchUsers(queryUsers)];
  }

  Future<List<db.User>?> _fetchUsers(List<String> ids) async {
    try {
      if (ids.length == 1) {
        final response = await client.userApi.getUserById(ids.first);
        return insertUpdateUsers([response.data]);
      } else {
        final response = await client.userApi.getUsers(ids);
        return insertUpdateUsers(response.data);
      }
    } catch (e, s) {
      w('_fetchUsers error $e, stack: $s');
    }
  }

  Future<List<db.User>> insertUpdateUsers(List<User> users) async {
    final result = <db.User>[];
    for (final e in users) {
      final user = e.asDbUser;
      result.add(user);

      await _upsertUser(user);
      final app = e.app;
      if (app != null) {
        await _upsertApp(
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
            capabilities: app.capabilites?.toString(),
            creatorId: app.creatorId,
            resourcePatterns: app.resourcePatterns?.toString(),
            updatedAt: app.updatedAt,
          ),
        );
      }
    }
    DataBaseEventBus.instance.updateUsers(users.map((e) => e.userId));
    return result;
  }

  Future<void> refreshCircle({String? circleId}) async {
    if (circleId == null) {
      final res = await client.circleApi.getCircles();
      res.data.forEach((circle) async {
        await _upsertCircle(
          db.Circle(
            circleId: circle.circleId,
            name: circle.name,
            createdAt: circle.createdAt,
          ),
        );
        await _handleCircle(circle);
      });
    } else {
      final circle = (await client.circleApi.getCircle(circleId)).data;
      await _upsertCircle(
        db.Circle(
          circleId: circle.circleId,
          name: circle.name,
          createdAt: circle.createdAt,
        ),
      );
      await _handleCircle(circle);
    }

    if (refreshUserIdSet.isNotEmpty) {
      unawaited(refreshUsers(refreshUserIdSet.toList()));
      refreshUserIdSet.clear();
    }
  }

  Future<void> _handleCircle(CircleResponse circle, {int? offset}) async {
    final ccList = (await client.circleApi.getCircleConversations(
      circle.circleId,
    )).data;
    for (final cc in ccList) {
      await _upsertCircleConversations([
        db.CircleConversation(
          conversationId: cc.conversationId,
          circleId: cc.circleId,
          createdAt: cc.createdAt,
        ),
      ]);
      if (cc.userId != null && !refreshUserIdSet.contains(cc.userId)) {
        final u = await database.userDao.userById(cc.userId!).getSingleOrNull();
        if (u == null) {
          refreshUserIdSet.add(cc.userId!);
        }
      }
    }
    if (ccList.length >= 500) {
      await _handleCircle(circle, offset: offset ?? 0 + 500);
    }
  }

  Future<void> _upsertConversation(db.Conversation conversation) async {
    await _requestDbWrite(
      DbWriteMethod.upsertConversation,
      payload: conversation,
    );
  }

  Future<void> _replaceParticipants(
    String conversationId,
    List<db.Participant> participants,
  ) async {
    await _requestDbWrite(
      DbWriteMethod.replaceParticipants,
      payload: DbWriteReplaceParticipantsPayload(
        conversationId: conversationId,
        participants: participants,
      ),
    );
  }

  Future<void> _replaceParticipantSessions(
    String conversationId,
    List<db.ParticipantSessionData> sessions,
  ) async {
    await _requestDbWrite(
      DbWriteMethod.replaceParticipantSessions,
      payload: DbWriteReplaceParticipantSessionsPayload(
        conversationId: conversationId,
        sessions: sessions,
      ),
    );
  }

  Future<void> _upsertUser(db.User user) async {
    await _requestDbWrite(DbWriteMethod.upsertUser, payload: user);
  }

  Future<void> _upsertApp(db.App app) async {
    await _requestDbWrite(DbWriteMethod.upsertApp, payload: app);
  }

  Future<void> _upsertCircle(db.Circle circle) async {
    await _requestDbWrite(
      DbWriteMethod.upsertCircle,
      payload: DbWriteCirclePayload(circle: circle),
    );
  }

  Future<void> _upsertCircleConversations(
    List<db.CircleConversation> items,
  ) async {
    if (items.isEmpty) return;
    await _requestDbWrite(
      DbWriteMethod.upsertCircleConversations,
      payload: DbWriteCircleConversationsPayload(items: items),
    );
  }

  Future<List<db.User>?> updateUserByIdentityNumber(
    String identityNumber,
  ) async {
    try {
      return await insertUpdateUsers([
        (await client.userApi.search(identityNumber)).data,
      ]);
    } catch (e, s) {
      w('updateUserByIdentityNumber error $e, stack: $s');
    }
  }
}
