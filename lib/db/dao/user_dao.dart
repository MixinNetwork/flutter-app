import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../../utils/extension/extension.dart';
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

  Future<int> insert(User user) => into(db.users).insertOnConflictUpdate(user);

  Future<int> insertSdkUser(sdk.User user) =>
      into(db.users).insertOnConflictUpdate(user.asDbUser);

  Future<void> insertAll(List<User> users) async => batch((batch) {
        batch.insertAllOnConflictUpdate(db.users, users);
      });

  Future<void> insertAllSdkUser(List<sdk.User> users) async => batch((batch) {
        batch.insertAllOnConflictUpdate(
            db.users, users.map((e) => e.asDbUser).toList());
      });

  Future deleteUser(User user) => delete(db.users).delete(user);

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
  }) =>
      db.fuzzySearchUser(
          id, username.trim().escapeSql(), identityNumber.trim().escapeSql());

  Selectable<String?> biography(String userId) =>
      db.biographyByIdentityNumber(userId);

  Future updateMuteUntil(String userId, String muteUntil) async {
    await (update(db.users)..where((tbl) => tbl.userId.equals(userId)))
        .write(UsersCompanion(muteUntil: Value(DateTime.tryParse(muteUntil))));
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
}
