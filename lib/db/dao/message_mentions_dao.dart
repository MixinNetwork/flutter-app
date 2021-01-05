import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'message_mentions_dao.g.dart';

@UseDao(tables: [MessagesHistory])
class MessageMentionsDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesHistoryDaoMixin {
  MessageMentionsDao(MixinDatabase db) : super(db);
}
