import 'package:drift/drift.dart';

import '../signal_database.dart';

part 'ratchet_sender_key_dao.g.dart';

@DriftAccessor()
class RatchetSenderKeyDao extends DatabaseAccessor<SignalDatabase>
    with _$RatchetSenderKeyDaoMixin {
  RatchetSenderKeyDao(super.db);

  Future<RatchetSenderKey?> getRatchetSenderKey(
    String groupId,
    String senderId,
  ) async =>
      (select(db.ratchetSenderKeys)..where(
        (tbl) => tbl.groupId.equals(groupId) & tbl.senderId.equals(senderId),
      )).getSingleOrNull();

  Future deleteByGroupIdAndSenderId(String groupId, String senderId) async =>
      (delete(db.ratchetSenderKeys)..where(
        (tbl) => tbl.groupId.equals(groupId) & tbl.senderId.equals(senderId),
      )).go();

  Future insertSenderKey(
    RatchetSenderKeysCompanion ratchetSenderKeysCompanion,
  ) async => into(db.ratchetSenderKeys).insert(ratchetSenderKeysCompanion);
}
