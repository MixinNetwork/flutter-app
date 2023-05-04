import 'package:drift/drift.dart';

import '../database_event_bus.dart';
import '../mixin_database.dart';

part 'circle_conversation_dao.g.dart';

@DriftAccessor(tables: [CircleConversation])
class CircleConversationDao extends DatabaseAccessor<MixinDatabase>
    with _$CircleConversationDaoMixin {
  CircleConversationDao(super.db);

  Future<int> insert(CircleConversation circleConversation) =>
      into(db.circleConversations)
          .insertOnConflictUpdate(circleConversation)
          .then((value) {
        DataBaseEventBus.instance.updateCircleConversation();
        return value;
      });

  SimpleSelectStatement<CircleConversations, CircleConversation>
      allCircleConversations(String circleId) => select(db.circleConversations)
        ..where((tbl) => tbl.circleId.equals(circleId));

  Future<int> deleteByCircleId(String circleId) =>
      db.deleteByCircleId(circleId).then((value) {
        DataBaseEventBus.instance.updateCircleConversation();
        return value;
      });

  Future<int> deleteById(String conversationId, String circleId) =>
      db.deleteByIds(conversationId, circleId).then((value) {
        DataBaseEventBus.instance.updateCircleConversation();
        return value;
      });
}
