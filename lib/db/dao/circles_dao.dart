import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'circles_dao.g.dart';

@UseDao(tables: [Circles])
class CirclesDao extends DatabaseAccessor<MixinDatabase>
    with _$CirclesDaoMixin {
  CirclesDao(MixinDatabase db) : super(db);

  Future<void> insertUpdate(Circle circle) async {
    await transaction(() async {
      final c = await ((select(db.circles)
            ..where((tbl) => tbl.circleId.equals(circle.circleId)))
          .getSingleOrNull());
      if (null == c) {
        return into(db.circles).insert(circle);
      } else {
        return into(db.circles).insertOnConflictUpdate(circle);
      }
    });
  }

  Future deleteCircle(Circle circle) => delete(db.circles).delete(circle);
}
