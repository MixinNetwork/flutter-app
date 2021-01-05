import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'users_dao.g.dart';

@UseDao(tables: [User])
class UserDao extends DatabaseAccessor<MixinDatabase> with _$UserDaoMixin {
  UserDao(MixinDatabase db) : super(db);
}
