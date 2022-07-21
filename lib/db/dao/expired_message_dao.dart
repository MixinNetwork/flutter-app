import 'package:drift/drift.dart';

import '../../constants/constants.dart';
import '../../utils/extension/extension.dart';
import '../mixin_database.dart';

part 'expired_message_dao.g.dart';

@DriftAccessor(tables: [ExpiredMessages])
class ExpiredMessageDao extends DatabaseAccessor<MixinDatabase>
    with _$ExpiredMessageDaoMixin {
  ExpiredMessageDao(super.attachedDatabase);

  Future<int> insert({
    required String messageId,
    required int expireIn,
    int? expireAt,
  }) =>
      into(db.expiredMessages).insertOnConflictUpdate(
        ExpiredMessagesCompanion.insert(
          messageId: messageId,
          expireIn: expireIn,
          expireAt: Value(expireAt),
        ),
      );

  Future<void> deleteByMessageId(String messageId) =>
      (delete(db.expiredMessages)
            ..where((tbl) => tbl.messageId.equals(messageId)))
          .go();

  Future<void> deleteByMessageIds(List<String> messageIds) =>
      (delete(db.expiredMessages)
            ..where((tbl) => tbl.messageId.isIn(messageIds)))
          .go();

  Future<List<ExpiredMessage>> getCurrentExpiredMessages() => db
      .getExpiredMessages(DateTime.now().millisecondsSinceEpoch ~/ 1000, 20)
      .get();

  Future<void> onMessageRead(Iterable<String> messageIds) async {
    final chunkedMessageIds =
        messageIds.toList(growable: false).chunked(kMarkLimit);
    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    for (final ids in chunkedMessageIds) {
      await db.markExpiredMessageRead(now, (em) => em.messageId.isIn(ids));
    }
  }

  Future<int> updateMessageExpireAt(String messageId, int expiredAt) =>
      (update(db.expiredMessages)
            ..where((tbl) => tbl.messageId.equals(messageId)))
          .write(
        ExpiredMessagesCompanion(expireAt: Value(expiredAt)),
      );

  Future<Map<String, int?>> getMessageExpireAt(List<String> messageIds) async {
    final messages = await (select(db.expiredMessages)
          ..where((tbl) => tbl.messageId.isIn(messageIds)))
        .get();
    return Map.fromEntries(messages.map(
      (e) => MapEntry(e.messageId, e.expireAt),
    ));
  }
}
