import 'package:drift/drift.dart';

import '../mixin_database.dart';

part 'flood_message_dao.g.dart';

@DriftAccessor(include: {'../moor/dao/flood.drift'})
class FloodMessageDao extends DatabaseAccessor<MixinDatabase>
    with _$FloodMessageDaoMixin {
  FloodMessageDao(super.db);

  Future<int> insert(FloodMessage message) =>
      into(db.floodMessages).insertOnConflictUpdate(message);

  Future deleteFloodMessage(FloodMessage message) =>
      delete(db.floodMessages).delete(message);

  SimpleSelectStatement<FloodMessages, FloodMessage> floodMessage() =>
      select(db.floodMessages)
        ..orderBy([(u) => OrderingTerm(expression: u.createdAt)])
        ..limit(10);

  Future<FloodMessage> findFloodMessageById(String messageId) {
    final query = select(db.floodMessages)
      ..where((tbl) => tbl.messageId.equals(messageId));
    return query.getSingle();
  }

  Future<int> getFloodMessageCount() {
    final countExp = db.floodMessages.messageId.count();
    final query = selectOnly(db.floodMessages)..addColumns([countExp]);
    return query.map((row) => row.read(countExp)!).getSingle();
  }

  Future<DateTime?> getLastBlazeMessageCreatedAt() =>
      _getLastBlazeMessageCreatedAt().getSingleOrNull();
}
