import 'package:drift/drift.dart';

import '../mixin_database.dart';

part 'circle_conversation_dao.g.dart';

@DriftAccessor(tables: [CircleConversation])
class CircleConversationDao extends DatabaseAccessor<MixinDatabase>
    with _$CircleConversationDaoMixin {
  CircleConversationDao(MixinDatabase db) : super(db);

  Future<int> insert(CircleConversation circleConversation) =>
      into(db.circleConversations).insertOnConflictUpdate(circleConversation);

  Future<int> deleteCircleConversation(CircleConversation circleConversation) =>
      delete(db.circleConversations).delete(circleConversation);

  SimpleSelectStatement<CircleConversations, CircleConversation>
      allCircleConversations(String circleId) => select(db.circleConversations)
        ..where((tbl) => tbl.circleId.equals(circleId));

  Future<int> deleteByCircleId(String circleId) =>
      db.deleteByCircleId(circleId);

  Future<int> deleteByIds(String conversationId, String circleId) =>
      db.deleteByIds(conversationId, circleId);
}
