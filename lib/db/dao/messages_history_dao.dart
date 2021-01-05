import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'messages_history_dao.g.dart';

@UseDao(tables: [MessagesHistory])
class MessagesHistoryDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesHistoryDaoMixin {
  MessagesHistoryDao(MixinDatabase db) : super(db);
}
