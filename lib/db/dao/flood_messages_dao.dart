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

  Future<List<FloodMessage>> findFloodMessage() {
    final query = select(db.floodMessages)
      ..limit(20)
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.get();
  }
}
