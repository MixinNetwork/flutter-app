import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../../ui/provider/slide_category_provider.dart';
import '../../utils/extension/extension.dart';
import '../database_event_bus.dart';
import '../extension/db.dart';
import '../mixin_database.dart';
import '../util/util.dart';

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
    isDeactivated: isDeactivated,
    membership: membership,
  );
}

@DriftAccessor(include: {'../moor/dao/user.drift'})
class UserDao extends DatabaseAccessor<MixinDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  Future<int> insert(User user, {bool updateIfConflict = true}) =>
      into(
        db.users,
      ).simpleInsert(user, updateIfConflict: updateIfConflict).then((value) {
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

  Future<void> insertAll(List<User> users) async =>
      batch((batch) {
        batch.insertAllOnConflictUpdate(db.users, users);
      }).then((value) {
        DataBaseEventBus.instance.updateUsers(users.map((e) => e.userId));
        return value;
      });

  Future<void> insertAllSdkUser(List<sdk.User> users) async =>
      batch((batch) {
        batch.insertAllOnConflictUpdate(
          db.users,
          users.map((e) => e.asDbUser).toList(),
        );
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
  }) => _fuzzySearchBotGroupUser(
    conversationId,
    DateTime.now().subtract(const Duration(days: 7)),
    currentUserId,
    keyword,
    keyword,
  );

  Selectable<User> friends() => (select(db.users)
    ..where(
      (tbl) => tbl.relationship.equalsValue(sdk.UserRelationship.friend),
    )
    ..orderBy([
      (tbl) => OrderingTerm.asc(tbl.fullName),
      (tbl) => OrderingTerm.asc(tbl.userId),
    ]));

  Selectable<User> fuzzySearchUser({
    required String id,
    required String username,
    required String identityNumber,
    bool isIncludeConversation = false,
    SlideCategoryState? category,
  }) {
    if (category?.type == SlideCategoryType.circle) {
      final circleId = category!.id;
      return _fuzzySearchUserInCircle(
        (_, conversation, _) {
          if (!isIncludeConversation) {
            return conversation.status.isNull();
          }
          return const Constant(true);
        },
        id,
        username,
        identityNumber,
        circleId,
      );
    }
    return _fuzzySearchUser(
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
            return users.relationship.equalsValue(sdk.UserRelationship.friend) &
                users.appId.isNull();
          case SlideCategoryType.groups:
            return const Constant(false);
          case SlideCategoryType.bots:
            return users.appId.isNotNull();
          case SlideCategoryType.strangers:
            return users.relationship.equalsValue(
                  sdk.UserRelationship.stranger,
                ) &
                users.appId.isNull();
          case SlideCategoryType.circle:
          case SlideCategoryType.setting:
            assert(false, 'Unsupported category: $category');
            return const Constant(false);
        }
      },
    );
  }

  Selectable<SearchItem> fuzzySearchUserItem(
    String keyword,
    String currentUserId,
  ) => db.fuzzySearchUserItem(
    keyword,
    (users) =>
        users.relationship.equalsValue(sdk.UserRelationship.friend) &
        (users.fullName.likeEscape('%$keyword%') |
            users.identityNumber.likeEscape('%$keyword%')),
    (users) => maxLimit,
  );

  Future updateMuteUntil(String userId, String muteUntil) async {
    await (update(db.users)..where(
          (tbl) => tbl.userId.equals(userId),
        ))
        .write(UsersCompanion(muteUntil: Value(DateTime.tryParse(muteUntil))));

    DataBaseEventBus.instance.updateUsers([userId]);
  }

  Future<List<String>> findMultiUserIdsByIdentityNumbers(
    Iterable<String> identityNumbers,
  ) async =>
      (select(db.users)..where(
            (tbl) => tbl.identityNumber.isIn(identityNumbers),
          ))
          .map((row) => row.userId)
          .get();

  Future<bool> hasUser(String userIdOrIdentityNumber) => db.hasData(
    db.users,
    [],
    db.users.userId.equals(userIdOrIdentityNumber) |
        db.users.identityNumber.equals(userIdOrIdentityNumber),
  );

  Future<List<User>> getUsers({required int limit, required int offset}) =>
      (select(db.users)
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.rowId)])
            ..limit(limit, offset: offset))
          .get();
}
