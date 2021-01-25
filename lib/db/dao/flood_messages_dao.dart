import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'flood_messages_dao.g.dart';

@UseDao(tables: [FloodMessages])
class FloodMessagesDao extends DatabaseAccessor<MixinDatabase>
    with _$FloodMessagesDaoMixin {
  FloodMessagesDao(MixinDatabase db) : super(db);

  Future<int> insert(FloodMessage message) =>
      into(db.floodMessages).insertOnConflictUpdate(message);

  Future deleteFloodMessage(FloodMessage message) =>
      delete(db.floodMessages).delete(message);

  Stream<List<FloodMessage>> findFloodMessage() {
    final query = select(db.floodMessages);
    return query.watch();
  }

  Future<FloodMessage> findFloodMessageById(String messageId) {
    final query = select(db.floodMessages)
      ..where((tbl) => tbl.messageId.equals(messageId));
    return query.getSingle();
  }

  Future<int> getFloodMessageCount() {
    final countExp = db.floodMessages.messageId.count();
    final query = selectOnly(db.floodMessages)..addColumns([countExp]);
    return query.map((row) => row.read(countExp)).getSingle();
  }
}
