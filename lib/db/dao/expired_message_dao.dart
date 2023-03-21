import 'package:drift/drift.dart';

import '../../constants/constants.dart';
import '../../utils/extension/extension.dart';
import '../database_event_bus.dart';
import '../mixin_database.dart';

part 'expired_message_dao.g.dart';

@DriftAccessor(
  tables: [ExpiredMessages],
  include: {
    '../moor/dao/expired_message.drift',
  },
)
class ExpiredMessageDao extends DatabaseAccessor<MixinDatabase>
    with _$ExpiredMessageDaoMixin {
  ExpiredMessageDao(super.attachedDatabase);

  Future<void> insert({
    required String messageId,
    required int expireIn,
    int? expireAt,
  }) async {
    await into(db.expiredMessages).insertOnConflictUpdate(
      ExpiredMessagesCompanion.insert(
        messageId: messageId,
        expireIn: expireIn,
        expireAt: Value(expireAt),
      ),
    );
    DataBaseEventBus.instance.updateExpiredMessageTable();
  }

  Future<void> deleteByMessageId(String messageId) =>
      (delete(db.expiredMessages)
            ..where((tbl) => tbl.messageId.equals(messageId)))
          .go();

  Future<void> deleteByMessageIds(List<String> messageIds) =>
      (delete(db.expiredMessages)
            ..where((tbl) => tbl.messageId.isIn(messageIds)))
          .go();

  Future<List<ExpiredMessage>> getCurrentExpiredMessages() =>
      getExpiredMessages(DateTime.now().millisecondsSinceEpoch ~/ 1000, 20)
          .get();

  Future<void> onMessageRead(Iterable<String> messageIds) async {
    final chunkedMessageIds =
        messageIds.toList(growable: false).chunked(kMarkLimit);
    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    for (final ids in chunkedMessageIds) {
      await _markExpiredMessageRead(now, (em) => em.messageId.isIn(ids));
    }
    DataBaseEventBus.instance.updateExpiredMessageTable();
  }

  Future<Map<String, int?>> getMessageExpireAt(List<String> messageIds) async {
    final messages = await (select(db.expiredMessages)
          ..where((tbl) => tbl.messageId.isIn(messageIds)))
        .get();
    return Map.fromEntries(messages.map(
      (e) => MapEntry(e.messageId, e.expireAt),
    ));
  }
}
