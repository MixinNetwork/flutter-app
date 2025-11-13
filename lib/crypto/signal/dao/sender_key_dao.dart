import 'package:drift/drift.dart';

import '../signal_database.dart';

part 'sender_key_dao.g.dart';

@DriftAccessor()
class SenderKeyDao extends DatabaseAccessor<SignalDatabase>
    with _$SenderKeyDaoMixin {
  SenderKeyDao(super.db);

  Future<SenderKey?> getSenderKey(String groupId, String senderId) async =>
      (select(db.senderKeys)..where(
            (tbl) =>
                tbl.groupId.equals(groupId) & tbl.senderId.equals(senderId),
          ))
          .getSingleOrNull();

  Future<List<SenderKey>> getSenderKeys() async => select(db.senderKeys).get();

  Future insert(SenderKey senderKey) =>
      into(db.senderKeys).insertOnConflictUpdate(senderKey);

  Future deleteByGroupIdAndSenderId(String groupId, String senderId) async =>
      (delete(db.senderKeys)..where(
            (tbl) =>
                tbl.groupId.equals(groupId) & tbl.senderId.equals(senderId),
          ))
          .go();
}
