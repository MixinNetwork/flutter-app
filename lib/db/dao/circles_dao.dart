import 'package:flutter_app/db/dao/users_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'circles_dao.g.dart';

@UseDao(tables: [Circles])
class CirclesDao extends DatabaseAccessor<MixinDatabase>
    with _$CirclesDaoMixin {
  CirclesDao(MixinDatabase db) : super(db);
  Future<int> insert(Circle circle) => into(db.circles).insert(circle);

  Future deleteCircle(Circle circle) => delete(db.circles).delete(circle);
}
