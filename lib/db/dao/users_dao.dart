import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'users_dao.g.dart';

@UseDao(tables: [User])
class UserDao extends DatabaseAccessor<MixinDatabase> with _$UserDaoMixin {
  UserDao(MixinDatabase db) : super(db);

  Future<int> insert(User user) => into(db.users).insertOnConflictUpdate(user);

  void insertAll(List<User> users) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(db.users, users);
    });
  }

  Future deleteUser(User user) => delete(db.users).delete(user);

  Future<User> findUserById(userId) {
    final query = select(db.users)..where((tbl) => tbl.userId.equals(userId));
    return query.getSingle();
  }

  Selectable<User> fuzzySearchGroupUser({
    String id,
    String conversationId,
    String username,
    String identityNumber,
  }) =>
      db.fuzzySearchGroupUser(
        id,
        conversationId,
        username,
        identityNumber,
      );

  Selectable<User> groupParticipants({
    String conversationId,
    String id,
  }) =>
      db.groupParticipants(
        conversationId,
        id,
      );
}
