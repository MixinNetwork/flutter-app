import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'sent_session_sender_key_dao.g.dart';

@UseDao(tables: [SentSessionSenderKeys])
class SentSessionSenderKeyDao extends DatabaseAccessor<MixinDatabase>
    with _$SentSessionSenderKeyDaoMixin {
  SentSessionSenderKeyDao(MixinDatabase db) : super(db);

  Future<int> insert(SentSessionSenderKey key) =>
      into(db.sentSessionSenderKeys).insertOnConflictUpdate(key);

  Future deleteSentSessionSenderKey(SentSessionSenderKey key) =>
      delete(db.sentSessionSenderKeys).delete(key);
}
