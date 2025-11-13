import 'package:drift/drift.dart';

import '../database_event_bus.dart';
import '../mixin_database.dart';

part 'circle_dao.g.dart';

@DriftAccessor(include: {'../moor/dao/circle.drift'})
class CircleDao extends DatabaseAccessor<MixinDatabase> with _$CircleDaoMixin {
  CircleDao(super.db);

  Future<void> insertUpdate(Circle circle) async {
    await transaction(() async {
      final c =
          await (select(db.circles)..where(
                (tbl) => tbl.circleId.equals(circle.circleId),
              ))
              .getSingleOrNull();
      return null == c
          ? into(db.circles).insert(circle)
          : into(db.circles).insertOnConflictUpdate(circle);
    });
    DataBaseEventBus.instance.updateCircle();
  }

  Future<int> deleteCircleById(String circleId) =>
      (delete(
        db.circles,
      )..where((tbl) => tbl.circleId.equals(circleId))).go().then((value) {
        DataBaseEventBus.instance.updateCircle();
        return value;
      });

  Future<Circle?> findCircleById(String circleId) => (select(
    db.circles,
  )..where((t) => t.circleId.equals(circleId))).getSingleOrNull();

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
      (batch) => batch.insertAllOnConflictUpdate(db.circles, newCircles),
    ).then((value) {
      DataBaseEventBus.instance.updateCircle();
      return value;
    });
  }
}
