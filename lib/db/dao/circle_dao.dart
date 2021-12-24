import 'package:drift/drift.dart';

import '../mixin_database.dart';

part 'circle_dao.g.dart';

@DriftAccessor(tables: [Circles])
class CircleDao extends DatabaseAccessor<MixinDatabase> with _$CircleDaoMixin {
  CircleDao(MixinDatabase db) : super(db);

  Future<void> insertUpdate(Circle circle) async {
    await transaction(() async {
      final c = await (select(db.circles)
            ..where((tbl) => tbl.circleId.equals(circle.circleId)))
          .getSingleOrNull();
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

  Future<void> updateOrders(List<ConversationCircleItem> value) {
    final now = DateTime.now();
    final newCircles = value.asMap().entries.map((e) {
      final index = e.key;
      final circle = e.value;
      return Circle(
        createdAt: circle.createdAt,
        circleId: circle.circleId,
        name: circle.name,
        orderedAt: now.add(Duration(milliseconds: index)),
      );
    });
    return batch(
        (batch) => batch.insertAllOnConflictUpdate(db.circles, newCircles));
  }
}
