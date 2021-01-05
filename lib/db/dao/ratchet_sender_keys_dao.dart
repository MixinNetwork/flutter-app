import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'ratchet_sender_keys_dao.g.dart';

@UseDao(tables: [MessagesHistory])
class MessagesHistoryDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesHistoryDaoMixin {
  MessagesHistoryDao(MixinDatabase db) : super(db);
}
