import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'ratchet_sender_keys_dao.g.dart';

@UseDao(tables: [RatchetSenderKeys])
class RatchetSenderKeysDao extends DatabaseAccessor<MixinDatabase>
    with _$RatchetSenderKeysDaoMixin {
  RatchetSenderKeysDao(MixinDatabase db) : super(db);
}
