import 'package:drift/drift.dart';

import '../mixin_database.dart';
import '../util/util.dart';

part 'pin_message_dao.g.dart';

@DriftAccessor(tables: [PinMessages])
class PinMessageDao extends DatabaseAccessor<MixinDatabase>
    with _$PinMessageDaoMixin {
  PinMessageDao(MixinDatabase attachedDatabase) : super(attachedDatabase);

  Future<int> insert(PinMessage pinMessage) =>
      into(db.pinMessages).insertOnConflictUpdate(pinMessage);

  Future<int> deleteByIds(List<String> messageIds) =>
      (delete(db.pinMessages)..where((tbl) => tbl.messageId.isIn(messageIds)))
          .go();

  Future<int> deleteByConversationId(String conversationId) =>
      (delete(db.pinMessages)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .go();

  Selectable<String?> getPinMessageIds(String conversationId) =>
      (selectOnly(db.pinMessages)
            ..addColumns([db.pinMessages.messageId])
            ..where(db.pinMessages.conversationId.equals(conversationId))
            ..orderBy([OrderingTerm.desc(db.pinMessages.createdAt)]))
          .map((row) => row.read(db.pinMessages.messageId));

  Selectable<PinMessageItemResult> pinMessageItem(
          String conversationId, String messageId) =>
      db.pinMessageItem(conversationId, messageId);

  Selectable<MessageItem> messageItems(String conversationId) =>
      db.basePinMessageItems(
        conversationId,
        (_, message, __, ___, ____, _____, ______, _______, ________, _________,
                __________, em) =>
            OrderBy([OrderingTerm.asc(message.createdAt)]),
        (_, __, ___, ____, _____, ______, _______, ________, _________,
                __________, ___________, em) =>
            maxLimit,
      );
}
