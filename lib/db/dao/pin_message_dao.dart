import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'pin_message_dao.g.dart';

@UseDao(tables: [
  PinMessages
], include: {
  '../moor/dao/pin_message.moor',
})
class PinMessageDao extends DatabaseAccessor<MixinDatabase>
    with _$PinMessageDaoMixin {
  PinMessageDao(MixinDatabase attachedDatabase) : super(attachedDatabase);

  Future<int> insert(PinMessage pinMessage) =>
      into(pinMessages).insertOnConflictUpdate(pinMessage);

  Future<int> deleteByIds(List<String> messageIds) =>
      (delete(pinMessages)..where((tbl) => tbl.messageId.isIn(messageIds)))
          .go();
}
