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

  Future<User?> findUserById(userId) async =>
      (select(db.users)..where((tbl) => tbl.userId.equals(userId)))
          .getSingleOrNull();

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
}
