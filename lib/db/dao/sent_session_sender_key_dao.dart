import 'package:drift/drift.dart';

import '../mixin_database.dart';

part 'sent_session_sender_key_dao.g.dart';

@DriftAccessor()
class SentSessionSenderKeyDao extends DatabaseAccessor<MixinDatabase>
    with _$SentSessionSenderKeyDaoMixin {
  SentSessionSenderKeyDao(super.db);

  Future<int> insert(SentSessionSenderKey key) =>
      into(db.sentSessionSenderKeys).insertOnConflictUpdate(key);

  Future deleteSentSessionSenderKey(SentSessionSenderKey key) =>
      delete(db.sentSessionSenderKeys).delete(key);
}
