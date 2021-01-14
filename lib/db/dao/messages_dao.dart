import 'package:flutter_app/db/insert_or_update_event_server.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'messages_dao.g.dart';

@UseDao(tables: [Messages])
class MessagesDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesDaoMixin {
  MessagesDao(MixinDatabase db) : super(db);

  InsertOrUpdateEventServer insertOrUpdateEventServer;

  Future<int> insert(Message message) async {
    final result = await into(db.messages).insertOnConflictUpdate(message);
    insertOrUpdateEventServer.conversationInsertOrUpdateController
        .add(message.conversationId);
    return result;
  }

  Future deleteMessage(Message message) => delete(db.messages).delete(message);
}
