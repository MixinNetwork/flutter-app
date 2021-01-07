import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'circle_conversations_dao.g.dart';

@UseDao(tables: [CircleConversation])
class CircleConversationDao extends DatabaseAccessor<MixinDatabase>
    with _$CircleConversationDaoMixin {
  CircleConversationDao(MixinDatabase db) : super(db);

  Future<int> insert(CircleConversation circleConversation) =>
      into(db.circleConversations).insert(circleConversation);

  Future deleteCircleConversation(CircleConversation circleConversation) =>
      delete(db.circleConversations).delete(circleConversation);
}
