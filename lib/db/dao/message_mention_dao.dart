import 'package:drift/drift.dart';

import '../../utils/extension/extension.dart';
import '../../utils/reg_exp_utils.dart';
import '../database_event_bus.dart';
import '../extension/db.dart';
import '../mixin_database.dart';
import 'message_dao.dart';

part 'message_mention_dao.g.dart';

@DriftAccessor()
class MessageMentionDao extends DatabaseAccessor<MixinDatabase>
    with _$MessageMentionDaoMixin {
  MessageMentionDao(super.db);

  Future<int> insert(
    MessageMention messageMention, {
    bool updateIfConflict = true,
  }) => into(db.messageMentions)
      .simpleInsert(messageMention, updateIfConflict: updateIfConflict)
      .then((value) {
        DataBaseEventBus.instance.updateMessageMention([
          MiniMessageItem(
            conversationId: messageMention.conversationId,
            messageId: messageMention.messageId,
          ),
        ]);
        return value;
      });

  Future deleteMessageMention(MessageMention messageMention) =>
      (delete(db.messageMentions)..where(
            (tbl) => tbl.messageId.equals(messageMention.messageId),
          ))
          .go()
          .then((value) {
            DataBaseEventBus.instance.updateMessageMention([
              MiniMessageItem(
                conversationId: messageMention.conversationId,
                messageId: messageMention.messageId,
              ),
            ]);
            return value;
          });

  Future<void> parseMentionData(
    String? content,
    String messageId,
    String conversationId,
    String senderId,
    QuoteMessageItem? quoteMessage,
    String currentUserId,
    String currentUserIdentityNumber,
  ) async {
    var mentionMe = false;
    if (content?.isNotEmpty == true) {
      final numbers = mentionNumberRegExp
          .allMatchesAndSort(content!)
          .map((e) => e[1]!);
      mentionMe =
          senderId != currentUserId &&
          numbers.contains(currentUserIdentityNumber);
    }

    if (!mentionMe &&
        quoteMessage != null &&
        quoteMessage.userId == currentUserId &&
        senderId != currentUserId) {
      mentionMe = true;
    }

    if (!mentionMe) return;

    await insert(
      MessageMention(
        messageId: messageId,
        conversationId: conversationId,
        hasRead: false,
      ),
    );
  }

  SimpleSelectStatement<MessageMentions, MessageMention>
  unreadMentionMessageByConversationId(String conversationId) =>
      (db.select(
        db.messageMentions,
      )..where(
        (tbl) =>
            tbl.conversationId.equals(conversationId) &
            tbl.hasRead.equals(false),
      ));

  Future<void> markMentionRead(String messageId) async {
    final messageMention = await (db.select(
      db.messageMentions,
    )..where((tbl) => tbl.messageId.equals(messageId))).getSingleOrNull();

    if (messageMention == null) return;
    if (messageMention.hasRead ?? false) return;

    await (db.update(db.messageMentions)
          ..where((tbl) => tbl.messageId.equals(messageId)))
        .write(const MessageMentionsCompanion(hasRead: Value(true)))
        .then((value) {
          DataBaseEventBus.instance.updateMessageMention([
            MiniMessageItem(
              conversationId: messageMention.conversationId,
              messageId: messageId,
            ),
          ]);
          return value;
        });
  }

  Future<List<MessageMention>> getMessageMentions(
    int kQueryLimit,
    int offset,
  ) =>
      (db.select(db.messageMentions)
            ..orderBy([
              (t) => OrderingTerm(expression: t.rowId, mode: OrderingMode.desc),
            ])
            ..limit(kQueryLimit, offset: offset))
          .get();

  Future<int> getMessageMentionsCount() => db
      .customSelect('SELECT COUNT(1) as _result FROM message_mentions')
      .map((p0) => p0.read<int>('_result'))
      .getSingle();

  Future<void> clearMessageMentionByConversationId(String conversationId) =>
      (db.delete(
        db.messageMentions,
      )..where((tbl) => tbl.conversationId.equals(conversationId))).go();
}
