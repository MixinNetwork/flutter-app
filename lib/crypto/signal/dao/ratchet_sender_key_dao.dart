import 'package:moor/moor.dart';

import '../signal_database.dart';

part 'ratchet_sender_key_dao.g.dart';

@UseDao(tables: [RatchetSenderKeys])
class RatchetSenderKeyDao extends DatabaseAccessor<SignalDatabase> {
  RatchetSenderKeyDao(SignalDatabase db) : super(db);

  Future<RatchetSenderKey?> getRatchetSenderKey(String groupId, String senderId) async =>
      (select(db.ratchetSenderKeys)
        ..where((tbl) =>
        tbl.groupId.equals(groupId) & tbl.senderId.equals(senderId)))
          .getSingleOrNull();

  Future deleteByGroupIdAndSenderId(String groupId, String senderId) async =>
      (delete(db.ratchetSenderKeys)
        ..where((tbl) =>
        tbl.groupId.equals(groupId) & tbl.senderId.equals(senderId)))
          .go();

  Future insertSenderKey(RatchetSenderKeysCompanion ratchetSenderKeysCompanion) async =>
      into(db.ratchetSenderKeys).insert(ratchetSenderKeysCompanion);
}
