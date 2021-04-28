import 'package:flutter_app/db/mixin_database.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:moor/moor.dart';

part 'participants_dao.g.dart';

@UseDao(tables: [Participants])
class ParticipantsDao extends DatabaseAccessor<MixinDatabase>
    with _$ParticipantsDaoMixin {
  ParticipantsDao(MixinDatabase db) : super(db);

  Future<int> insert(Participant participant) =>
      into(db.participants).insertOnConflictUpdate(participant);

  void deleteParticipant(Participant participant) async =>
      delete(db.participants).delete(participant);

  Future<List<Participant>> getParticipants(String conversationId) async {
    final query = select(db.participants)
      ..where((tbl) => tbl.conversationId.equals(conversationId));
    return query.get();
  }

  void insertAll(List<Participant> add) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(db.participants, add);
    });
  }

  void deleteAll(Iterable<Participant> remove) {
    remove.forEach(deleteParticipant);
  }

  Selectable<User> participantsAvatar(String conversationId) =>
      db.participantsAvatar(conversationId);

  void updateParticipantRole(
      String conversationId, String participantId, ParticipantRole role) async {
    await db.customUpdate(
      'UPDATE participants SET role = ? where conversation_id = ? AND user_id = ?',
      variables: [
        Variable<ParticipantRole>(role),
        Variable.withString(conversationId),
        Variable.withString(participantId)
      ],
      updates: {db.participants},
      updateKind: UpdateKind.update,
    );
  }
}
