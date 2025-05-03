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
    final pinMessages =
        await (select(db.pinMessages)
          ..where((tbl) => tbl.messageId.isIn(messageIds))).get();
    if (pinMessages.isEmpty) return;

    await (delete(db.pinMessages)
      ..where((tbl) => tbl.messageId.isIn(messageIds))).go();

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
    final pinMessages =
        await (select(db.pinMessages)
          ..where((tbl) => tbl.conversationId.equals(conversationId))).get();
    if (pinMessages.isEmpty) return;

    await (delete(db.pinMessages)
      ..where((tbl) => tbl.conversationId.equals(conversationId))).go();

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
        (
          _,
          message,
          __,
          ___,
          ____,
          _____,
          ______,
          _______,
          ________,
          _________,
          __________,
          ____________,
          _____________,
          ______________,
          em,
        ) => OrderBy([OrderingTerm.asc(message.createdAt)]),
        (
          _,
          __,
          ___,
          ____,
          _____,
          ______,
          _______,
          ________,
          _________,
          __________,
          ___________,
          ____________,
          _____________,
          ______________,
          em,
        ) => maxLimit,
      );

  Future<List<PinMessage>> getPinMessages({
    required int limit,
    required int offset,
  }) =>
      (select(db.pinMessages)
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.rowId)])
            ..limit(limit, offset: offset))
          .get();
}
