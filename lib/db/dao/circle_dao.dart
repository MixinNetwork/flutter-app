import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'circle_dao.g.dart';

@UseDao(tables: [Circles])
class CircleDao extends DatabaseAccessor<MixinDatabase> with _$CircleDaoMixin {
  CircleDao(MixinDatabase db) : super(db);

  Future<void> insertUpdate(Circle circle) async {
    final c = await (select(db.circles)
      ..where((tbl) => tbl.circleId.equals(circle.circleId)))
        .getSingleOrNull();
    await transaction(() async {
      if (null == c) {
        return into(db.circles).insert(circle);
      } else {
        return into(db.circles).insertOnConflictUpdate(circle);
      }
    });
  }

  Future<int> deleteCircle(String circleId) =>
      (delete(db.circles)..where((tbl) => tbl.circleId.equals(circleId))).go();

  Selectable<ConversationCircleItem> allCircles() => db.allCircles();

  Selectable<ConversationCircleManagerItem> circleByConversationId(
          String conversationId) =>
      db.circleByConversationId(conversationId);

  Future<Circle?> findCircleById(String circleId) =>
      (select(db.circles)..where((t) => t.circleId.equals(circleId)))
          .getSingleOrNull();

  Selectable<ConversationCircleManagerItem> otherCircleByConversationId(
          String conversationId) =>
      db.otherCircleByConversationId(conversationId);

  Selectable<String> circlesNameByConversationId(String conversationId) =>
      db.circlesNameByConversationId(conversationId);

  Future<int> deleteCircleById(String circleId) =>
      db.deleteCircleById(circleId);
}
