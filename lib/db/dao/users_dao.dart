import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'users_dao.g.dart';

@UseDao(tables: [User])
class UserDao extends DatabaseAccessor<MixinDatabase> with _$UserDaoMixin {
  UserDao(MixinDatabase db) : super(db);

  Future<int> insert(User user) => into(db.users).insertOnConflictUpdate(user);

  Future<void> insertAll(List<User> users) async => batch((batch) {
        batch.insertAllOnConflictUpdate(db.users, users);
      });

  Future deleteUser(User user) => delete(db.users).delete(user);

  SimpleSelectStatement<Users, User> findUserById(String userId) =>
      select(db.users)..where((tbl) => tbl.userId.equals(userId));

  Selectable<User> fuzzySearchGroupUser({
    required String id,
    required String conversationId,
    required String username,
    required String identityNumber,
  }) =>
      db.fuzzySearchGroupUser(
        id,
        conversationId,
        username,
        identityNumber,
      );

  Selectable<User> groupParticipants({
    required String conversationId,
    required String id,
  }) =>
      db.groupParticipants(
        conversationId,
        id,
      );

  Selectable<User> friends() => db.friends();

  Selectable<User> usersByIn(List<String> userIds) => db.usersByIn(userIds);

  Selectable<User> fuzzySearchUser({
    required String id,
    required String username,
    required String identityNumber,
  }) =>
      db.fuzzySearchUser(id, username, identityNumber);

  Selectable<String?> biography(String userId) =>
      db.biographyByIdentityNumber(userId);

  Future updateMuteUntil(String userId, String muteUntil) async {
    await (update(db.users)..where((tbl) => tbl.userId.equals(userId)))
        .write(UsersCompanion(muteUntil: Value(DateTime.tryParse(muteUntil))));
  }
}
