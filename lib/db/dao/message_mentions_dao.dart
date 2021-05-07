import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'message_mentions_dao.g.dart';

@UseDao(tables: [MessageMentions])
class MessageMentionsDao extends DatabaseAccessor<MixinDatabase>
    with _$MessageMentionsDaoMixin {
  MessageMentionsDao(MixinDatabase db) : super(db);

  Future<int> insert(MessageMention messageMention) =>
      into(db.messageMentions).insertOnConflictUpdate(messageMention);

  Future deleteMessageMention(MessageMention messageMention) =>
      delete(db.messageMentions).delete(messageMention);
}
