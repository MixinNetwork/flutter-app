import 'package:drift/drift.dart';

import '../database_event_bus.dart';
import '../extension/db.dart';
import '../mixin_database.dart';
import '../util/util.dart';
import 'message_dao.dart';

part 'pin_message_dao.g.dart';

@DriftAccessor(include: {'../moor/dao/pin_message.drift'})
class PinMessageDao extends DatabaseAccessor<MixinDatabase>
    with _$PinMessageDaoMixin {
  PinMessageDao(super.attachedDatabase);

  Future<int> insert(PinMessage pinMessage, {bool updateIfConflict = true}) =>
      into(db.pinMessages)
          .simpleInsert(pinMessage, updateIfConflict: updateIfConflict)
          .then((value) {
            DataBaseEventBus.instance.updatePinMessage([
              MiniMessageItem(
                conversationId: pinMessage.conversationId,
                messageId: pinMessage.messageId,
              ),
            ]);
            return value;
          });

  Future<void> deleteByIds(List<String> messageIds) async {
    final pinMessages = await (select(
      db.pinMessages,
    )..where((tbl) => tbl.messageId.isIn(messageIds))).get();
    if (pinMessages.isEmpty) return;

    await (delete(
      db.pinMessages,
    )..where((tbl) => tbl.messageId.isIn(messageIds))).go();

    DataBaseEventBus.instance.updatePinMessage(
      pinMessages.map(
        (e) => MiniMessageItem(
          conversationId: e.conversationId,
          messageId: e.messageId,
        ),
      ),
    );
  }

  Future<void> deleteByConversationId(String conversationId) async {
    final pinMessages = await (select(
      db.pinMessages,
    )..where((tbl) => tbl.conversationId.equals(conversationId))).get();
    if (pinMessages.isEmpty) return;

    await (delete(
      db.pinMessages,
    )..where((tbl) => tbl.conversationId.equals(conversationId))).go();

    DataBaseEventBus.instance.updatePinMessage(
      pinMessages.map(
        (e) => MiniMessageItem(
          conversationId: e.conversationId,
          messageId: e.messageId,
        ),
      ),
    );
  }

  Selectable<MessageItem> messageItems(String conversationId) =>
      db.basePinMessageItems(
        conversationId,
        (_, message, _, _, _, _, _, _, _, _, _, _, _, _, em) =>
            OrderBy([OrderingTerm.asc(message.createdAt)]),
        (_, _, _, _, _, _, _, _, _, _, _, _, _, _, em) => maxLimit,
      );

  Future<List<PinMessage>> pinMessagesByConversationId({
    required String conversationId,
    required int limit,
    String? beforeMessageId,
    String? afterMessageId,
    bool ascending = false,
  }) async {
    final before = beforeMessageId == null
        ? null
        : await pinMessageByMessageId(
            conversationId: conversationId,
            messageId: beforeMessageId,
          );
    if (beforeMessageId != null && before == null) {
      throw StateError('Pinned cursor message not found');
    }
    final after = afterMessageId == null
        ? null
        : await pinMessageByMessageId(
            conversationId: conversationId,
            messageId: afterMessageId,
          );
    if (afterMessageId != null && after == null) {
      throw StateError('Pinned cursor message not found');
    }
    return (select(db.pinMessages)
          ..where(
            (tbl) =>
                tbl.conversationId.equals(conversationId) &
                (before == null
                    ? const Constant(true)
                    : tbl.createdAt.isSmallerThanValue(
                            before.createdAt.millisecondsSinceEpoch,
                          ) |
                          (tbl.createdAt.equals(
                                before.createdAt.millisecondsSinceEpoch,
                              ) &
                              tbl.messageId.isSmallerThanValue(
                                before.messageId,
                              ))) &
                (after == null
                    ? const Constant(true)
                    : tbl.createdAt.isBiggerThanValue(
                            after.createdAt.millisecondsSinceEpoch,
                          ) |
                          (tbl.createdAt.equals(
                                after.createdAt.millisecondsSinceEpoch,
                              ) &
                              tbl.messageId.isBiggerThanValue(
                                after.messageId,
                              ))),
          )
          ..orderBy([
            (tbl) => ascending
                ? OrderingTerm.asc(tbl.createdAt)
                : OrderingTerm.desc(tbl.createdAt),
            (tbl) => ascending
                ? OrderingTerm.asc(tbl.messageId)
                : OrderingTerm.desc(tbl.messageId),
          ])
          ..limit(limit))
        .get();
  }

  Future<PinMessage?> pinMessageByMessageId({
    required String conversationId,
    required String messageId,
  }) =>
      (select(db.pinMessages)..where(
            (tbl) =>
                tbl.conversationId.equals(conversationId) &
                tbl.messageId.equals(messageId),
          ))
          .getSingleOrNull();

  Future<List<PinMessage>> getPinMessages({
    required int limit,
    required int offset,
  }) =>
      (select(db.pinMessages)
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.rowId)])
            ..limit(limit, offset: offset))
          .get();
}
