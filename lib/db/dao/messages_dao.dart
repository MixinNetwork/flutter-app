import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'messages_dao.g.dart';

@UseDao(tables: [Messages])
class MessagesDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesHistoryDaoMixin {
  MessagesDao(MixinDatabase db) : super(db);
}
