import 'package:drift/drift.dart';

import '../mixin_database.dart';

part 'expired_message_dao.g.dart';

@DriftAccessor(tables: [ExpiredMessages])
class ExpiredMessageDao extends DatabaseAccessor<MixinDatabase>
    with _$ExpiredMessageDaoMixin {
  ExpiredMessageDao(MixinDatabase attachedDatabase) : super(attachedDatabase);

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
}
