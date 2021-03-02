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

  Future<User?> findUserById(userId) async {
    final query = select(db.users)..where((tbl) => tbl.userId.equals(userId));
    final list = await query.get();
    return list.isEmpty ? null : list.first;
  }

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
}
