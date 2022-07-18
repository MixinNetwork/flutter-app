import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    hide User, transaction;

import '../mixin_database.dart';

part 'participant_dao.g.dart';

@DriftAccessor(tables: [Participants])
class ParticipantDao extends DatabaseAccessor<MixinDatabase>
    with _$ParticipantDaoMixin {
  ParticipantDao(super.db);

  Future<int> insert(Participant participant) =>
      into(db.participants).insertOnConflictUpdate(participant);

  Future<int> deleteParticipant(Participant participant) =>
      delete(db.participants).delete(participant);

  Future<List<Participant>> getParticipants(String conversationId) async {
    final query = select(db.participants)
      ..where((tbl) => tbl.conversationId.equals(conversationId));
    return query.get();
  }

  Selectable<ParticipantUser> groupParticipantsByConversationId(
          String conversationId) =>
      db.groupParticipantsByConversationId(conversationId);

  Future<String?> findJoinedConversationId(String userId) async => db
      .customSelect(
        'SELECT p.conversation_id FROM participants p, conversations c WHERE p.user_id = ? AND p.conversation_id = c.conversation_id AND c.status = 2 LIMIT 1',
        variables: [Variable.withString(userId)],
      )
      .map((row) => row.read<String>('conversation_id'))
      .getSingleOrNull();

  Future<void> insertAll(List<Participant> add) => batch((batch) {
        batch.insertAllOnConflictUpdate(db.participants, add);
      });

  Future<List<Participant>> getAllParticipants() async =>
      select(db.participants).get();

  Future<void> deleteAll(Iterable<Participant> remove) async {
    remove.forEach((element) async {
      await deleteParticipant(element);
    });
  }

  Selectable<User> participantsAvatar(String conversationId) =>
      db.participantsAvatar(conversationId);

  Future<int> updateParticipantRole(
          String conversationId, String participantId, ParticipantRole? role) =>
      db.customUpdate(
        'UPDATE participants SET role = ? where conversation_id = ? AND user_id = ?',
        variables: [
          Variable<String?>(const ParticipantRoleJsonConverter().toJson(role)),
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

  Future deleteByCIdAndPId(String conversationId, String participantId) async =>
      (delete(db.participants)
            ..where((tbl) =>
                tbl.conversationId.equals(conversationId) &
                tbl.userId.equals(participantId)))
          .go();

  Selectable<String> userIdByIdentityNumber(
          String conversationId, String identityNumber) =>
      db.userIdByIdentityNumber(conversationId, identityNumber);

  Selectable<int> conversationParticipantsCount(String conversationId) =>
      db.conversationParticipantsCount(conversationId);

  Selectable<Participant> participantById(
          String conversationId, String userId) =>
      (db.select(db.participants)
        ..where((tbl) =>
            tbl.conversationId.equals(conversationId) &
            tbl.userId.equals(userId)));
}
