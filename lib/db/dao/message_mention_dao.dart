import 'package:moor/moor.dart';

import '../../ui/home/bloc/multi_auth_cubit.dart';
import '../../utils/reg_exp_utils.dart';
import '../mixin_database.dart';

part 'message_mention_dao.g.dart';

@UseDao(tables: [MessageMentions])
class MessageMentionDao extends DatabaseAccessor<MixinDatabase>
    with _$MessageMentionDaoMixin {
  MessageMentionDao(MixinDatabase db) : super(db);

  Future<int> insert(MessageMention messageMention) =>
      into(db.messageMentions).insertOnConflictUpdate(messageMention);

  Future deleteMessageMention(MessageMention messageMention) =>
      delete(db.messageMentions).delete(messageMention);

  Future<int> deleteMessageMentionByMessageId(String messageId) =>
      db.deleteMessageMentionByMessageId(messageId);

  Future<void> parseMentionData(
    String content,
    String messageId,
    String conversationId,
    String senderId,
  ) async {
    final numbers = mentionNumberRegExp.allMatches(content).map((e) => e[1]!);
    final mentionMe = senderId != MultiAuthCubit.currentAccount?.userId &&
        numbers.contains(MultiAuthCubit.currentAccount?.identityNumber);
    if (!mentionMe) return;

    await insert(MessageMention(
      messageId: messageId,
      conversationId: conversationId,
      hasRead: false,
    ));
  }

  SimpleSelectStatement<MessageMentions, MessageMention>
      unreadMentionMessageByConversationId(String conversationId) =>
          (db.select(db.messageMentions)
            ..where((tbl) =>
                tbl.conversationId.equals(conversationId) &
                tbl.hasRead.equals(false)));

  Future<int> markMentionRead(String messageId) =>
      (db.update(db.messageMentions)
            ..where((tbl) => tbl.messageId.equals(messageId)))
          .write(const MessageMentionsCompanion(hasRead: Value(true)));
}
