import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'sent_session_sender_keys_dao.g.dart';

@UseDao(tables: [SentSessionSenderKeys])
class SentSessionSenderKeysDao extends DatabaseAccessor<MixinDatabase>
    with _$SentSessionSenderKeysDaoMixin {
  SentSessionSenderKeysDao(MixinDatabase db) : super(db);

  Future<int> insert(SentSessionSenderKey key) =>
      into(db.sentSessionSenderKeys).insertOnConflictUpdate(key);

  Future deleteSentSessionSenderKey(SentSessionSenderKey key) =>
      delete(db.sentSessionSenderKeys).delete(key);
}
