import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'flood_messages_dao.g.dart';

@UseDao(tables: [FloodMessages])
class FloodMessagesDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesHistoryDaoMixin {
  FloodMessagesDao(MixinDatabase db) : super(db);
}
