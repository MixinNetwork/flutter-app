import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'circle_conversations_dao.g.dart';

@UseDao(tables: [CircleConversation])
class CircleConversationDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesHistoryDaoMixin {
  CircleConversationDao(MixinDatabase db) : super(db);
}
