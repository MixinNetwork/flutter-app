import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'participants_dao.g.dart';

@UseDao(tables: [Participants])
class ParticipantsDao extends DatabaseAccessor<MixinDatabase>
    with _$ParticipantsDaoMixin {
  ParticipantsDao(MixinDatabase db) : super(db);

  Future<int> insert(Participant participant) =>
      into(db.participants).insertOnConflictUpdate(participant);

  Future<int> deleteParticipant(Participant participant) =>
      delete(db.participants).delete(participant);

  Future<List<Participant>> getParticipants(String conversationId) async {
    final query = select(db.participants)
      ..where((tbl) => tbl.conversationId.equals(conversationId));
    return query.get();
  }

  Future<void> insertAll(List<Participant> add) => batch((batch) {
        batch.insertAllOnConflictUpdate(db.participants, add);
      });

  Future<List<Participant>> getAllParticipants() async =>
      select(db.participants).get();

  void deleteAll(Iterable<Participant> remove) {
    remove.forEach(deleteParticipant);
  }

  Selectable<User> participantsAvatar(String conversationId) =>
      db.participantsAvatar(conversationId);

  Future<int> updateParticipantRole(
          String conversationId, String participantId, ParticipantRole role) =>
      db.customUpdate(
        'UPDATE participants SET role = ? where conversation_id = ? AND user_id = ?',
        variables: [
          Variable<ParticipantRole>(role),
          Variable.withString(conversationId),
          Variable.withString(participantId)
        ],
        updates: {db.participants},
        updateKind: UpdateKind.update,
      );

  Future replaceAll(String conversationId, List<Participant> list) async =>
      transaction(() async {
        await deleteByConversationId(conversationId);
        await insertAll(list);
      });

  Future deleteByConversationId(String conversationId) async {
    await (delete(db.participants)
          ..where((tbl) => tbl.conversationId.equals(conversationId)))
        .go();
  }
}
