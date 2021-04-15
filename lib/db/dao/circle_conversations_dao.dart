import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'circle_conversations_dao.g.dart';

@UseDao(tables: [CircleConversation])
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

  Future<int> deleteByCircleId(String circleId) => db.deleteByCircleId(circleId);
}
