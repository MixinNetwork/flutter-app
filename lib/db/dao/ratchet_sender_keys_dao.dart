import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'ratchet_sender_keys_dao.g.dart';

@UseDao(tables: [RatchetSenderKeys])
class RatchetSenderKeysDao extends DatabaseAccessor<MixinDatabase>
    with _$RatchetSenderKeysDaoMixin {
  RatchetSenderKeysDao(MixinDatabase db) : super(db);

  Future<int> insert(RatchetSenderKey key) =>
      into(db.ratchetSenderKeys).insertOnConflictUpdate(key);

  Future deleteRatchetSenderKey(RatchetSenderKey key) =>
      delete(db.ratchetSenderKeys).delete(key);
}
