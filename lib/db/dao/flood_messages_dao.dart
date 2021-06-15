import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'flood_messages_dao.g.dart';

@UseDao(tables: [FloodMessages])
class FloodMessagesDao extends DatabaseAccessor<MixinDatabase>
    with _$FloodMessagesDaoMixin {
  FloodMessagesDao(MixinDatabase db) : super(db);

  Future<int> insert(FloodMessage message) =>
      into(db.floodMessages).insertOnConflictUpdate(message);

  Future deleteFloodMessage(FloodMessage message) =>
      delete(db.floodMessages).delete(message);

  SimpleSelectStatement<FloodMessages, FloodMessage> findFloodMessage() =>
      select(db.floodMessages)
        ..orderBy([
          (u) => OrderingTerm(expression: u.createdAt, mode: OrderingMode.asc)
        ])
        ..limit(10);

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

  Future<DateTime?> getLastBlazeMessageCreatedAt() =>
      db.getLastBlazeMessageCreatedAt().getSingleOrNull();
}
