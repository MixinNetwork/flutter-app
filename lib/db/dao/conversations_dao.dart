import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'conversations_dao.g.dart';

@UseDao(tables: [Conversations])
class ConversationsDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesHistoryDaoMixin {
  ConversationsDao(MixinDatabase db) : super(db);
}
