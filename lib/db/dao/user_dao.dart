import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../../ui/home/bloc/slide_category_cubit.dart';
import '../../utils/extension/extension.dart';
import '../database_event_bus.dart';
import '../mixin_database.dart';

part 'user_dao.g.dart';

extension UserExtension on sdk.User {
  User get asDbUser => User(
        userId: userId,
        identityNumber: identityNumber,
        relationship: relationship,
        fullName: fullName,
        avatarUrl: avatarUrl,
        phone: phone,
        isVerified: isVerified,
        createdAt: createdAt,
        muteUntil: DateTime.tryParse(muteUntil),
        hasPin: hasPin == true ? 1 : 0,
        appId: app?.appId,
        biography: biography,
        isScam: isScam ? 1 : 0,
        codeId: codeId,
        codeUrl: codeUrl,
      );
}

@DriftAccessor(tables: [User])
class UserDao extends DatabaseAccessor<MixinDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  Future<int> insert(User user) =>
      into(db.users).insertOnConflictUpdate(user).then((value) {
        if (value > 0) {
          DataBaseEventBus.instance.updateUsers([user.userId]);
        }
        return value;
      });

  Future<int> insertSdkUser(sdk.User user) =>
      into(db.users).insertOnConflictUpdate(user.asDbUser).then((value) {
        if (value > 0) {
          DataBaseEventBus.instance.updateUsers([user.userId]);
        }
        return value;
      });

  Future<void> insertAll(List<User> users) async => batch((batch) {
        batch.insertAllOnConflictUpdate(db.users, users);
      }).then((value) {
        DataBaseEventBus.instance.updateUsers(users.map((e) => e.userId));
        return value;
      });

  Future<void> insertAllSdkUser(List<sdk.User> users) async => batch((batch) {
        batch.insertAllOnConflictUpdate(
            db.users, users.map((e) => e.asDbUser).toList());
      }).then((value) {
        DataBaseEventBus.instance.updateUsers(users.map((e) => e.userId));
        return value;
      });

  Future deleteUser(User user) => delete(db.users).delete(user).then((value) {
        if (value > 0) {
          DataBaseEventBus.instance.updateUsers([user.userId]);
        }
        return value;
      });

  SimpleSelectStatement<Users, User> userById(String userId) => select(db.users)
    ..where((tbl) => tbl.userId.equals(userId))
    ..limit(1);

  Selectable<String?> userFullNameByUserId(String userId) =>
      (selectOnly(db.users)
            ..addColumns([db.users.fullName])
            ..where(db.users.userId.equals(userId))
            ..limit(1))
          .map((row) => row.read(db.users.fullName));

  Selectable<User> fuzzySearchBotGroupUser({
    required String currentUserId,
    required String conversationId,
    required String keyword,
  }) =>
      db.fuzzySearchBotGroupUser(
        conversationId,
        DateTime.now().subtract(const Duration(days: 7)),
        currentUserId,
        keyword,
        keyword,
      );

  Selectable<User> fuzzySearchGroupUser({
    required String currentUserId,
    required String conversationId,
    required String keyword,
  }) =>
      db.fuzzySearchGroupUser(
        currentUserId,
        conversationId,
        keyword,
        keyword,
      );

  Selectable<User> groupParticipants({required String conversationId}) =>
      db.groupParticipants(conversationId);

  Selectable<User> friends() => (select(db.users)
    ..where((tbl) => tbl.relationship.equalsValue(sdk.UserRelationship.friend))
    ..orderBy([
      (tbl) => OrderingTerm.asc(tbl.fullName),
      (tbl) => OrderingTerm.asc(tbl.userId),
    ]));

  Selectable<User> notInFriends(List<String> filterIds) =>
      db.notInFriends(filterIds);

  Selectable<User> usersByIn(List<String> userIds) => db.usersByIn(userIds);

  Selectable<User> fuzzySearchUser({
    required String id,
    required String username,
    required String identityNumber,
    bool isIncludeConversation = false,
    SlideCategoryState? category,
  }) {
    if (category?.type == SlideCategoryType.circle) {
      final circleId = category!.id;
      return db.fuzzySearchUserInCircle((_, conversation, __) {
        if (!isIncludeConversation) {
          return conversation.status.isNull();
        }
        return const Constant(true);
      }, id, username, identityNumber, circleId);
    }
    return db.fuzzySearchUser(
        (_, conversation) {
          if (!isIncludeConversation) {
            return conversation.status.isNull();
          }
          return const Constant(true);
        },
        id,
        username.trim().escapeSql(),
        identityNumber.trim().escapeSql(),
        (users, _) {
          switch (category?.type) {
            case null:
            case SlideCategoryType.chats:
              return const Constant(true);
            case SlideCategoryType.contacts:
              return users.relationship
                      .equalsValue(sdk.UserRelationship.friend) &
                  users.appId.isNull();
            case SlideCategoryType.groups:
              return const Constant(false);
            case SlideCategoryType.bots:
              return users.appId.isNotNull();
            case SlideCategoryType.strangers:
              return users.relationship
                      .equalsValue(sdk.UserRelationship.stranger) &
                  users.appId.isNull();
            case SlideCategoryType.circle:
            case SlideCategoryType.setting:
              assert(false, 'Unsupported category: $category');
              return const Constant(false);
          }
        });
  }

  Selectable<String?> biography(String userId) =>
      db.biographyByIdentityNumber(userId);

  Future updateMuteUntil(String userId, String muteUntil) async {
    await (update(db.users)..where((tbl) => tbl.userId.equals(userId)))
        .write(UsersCompanion(muteUntil: Value(DateTime.tryParse(muteUntil))));

    DataBaseEventBus.instance.updateUsers([userId]);
  }

  Future<List<String>> findMultiUserIdsByIdentityNumbers(
          Iterable<String> identityNumbers) async =>
      (select(db.users)
            ..where((tbl) => tbl.identityNumber.isIn(identityNumbers)))
          .map((row) => row.userId)
          .get();

  Selectable<MentionUser> userByIdentityNumbers(List<String> list) =>
      db.userByIdentityNumbers(list);

  Future<bool> hasUser(String userIdOrIdentityNumber) => db.hasData(
      db.users,
      [],
      db.users.userId.equals(userIdOrIdentityNumber) |
          db.users.identityNumber.equals(userIdOrIdentityNumber));

  Future<List<User>> getUsers() => (select(db.users)
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.fullName),
            (tbl) => OrderingTerm.asc(tbl.userId),
          ]))
        .get();
}
