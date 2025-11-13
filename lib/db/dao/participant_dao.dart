import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    hide User, transaction;

import '../database_event_bus.dart';
import '../extension/db.dart';
import '../mixin_database.dart';

part 'participant_dao.g.dart';

class MiniParticipantItem with EquatableMixin {
  MiniParticipantItem({required this.conversationId, required this.userId});

  final String conversationId;
  final String userId;

  @override
  List<Object?> get props => [conversationId, userId];
}

@DriftAccessor(include: {'../moor/dao/participant.drift'})
class ParticipantDao extends DatabaseAccessor<MixinDatabase>
    with _$ParticipantDaoMixin {
  ParticipantDao(super.db);

  Future<int> insert(Participant participant, {bool updateIfConflict = true}) =>
      into(db.participants)
          .simpleInsert(participant, updateIfConflict: updateIfConflict)
          .then((value) {
            DataBaseEventBus.instance.updateParticipant([
              MiniParticipantItem(
                conversationId: participant.conversationId,
                userId: participant.userId,
              ),
            ]);
            return value;
          });

  Future<int> deleteParticipant(Participant participant) =>
      delete(db.participants).delete(participant).then((value) {
        DataBaseEventBus.instance.updateParticipant([
          MiniParticipantItem(
            conversationId: participant.conversationId,
            userId: participant.userId,
          ),
        ]);
        return value;
      });

  Future<List<Participant>> getParticipants(String conversationId) async {
    final query = select(db.participants)
      ..where((tbl) => tbl.conversationId.equals(conversationId));
    return query.get();
  }

  Future<String?> findJoinedConversationId(String userId) async =>
      _joinedConversationId(userId).getSingleOrNull();

  Future<void> insertAll(List<Participant> add) =>
      batch((batch) {
        batch.insertAllOnConflictUpdate(db.participants, add);
      }).then(
        (value) => DataBaseEventBus.instance.updateParticipant(
          add.map(
            (participant) => MiniParticipantItem(
              conversationId: participant.conversationId,
              userId: participant.userId,
            ),
          ),
        ),
      );

  Future<void> deleteAll(Iterable<Participant> remove) async {
    remove.forEach((element) async {
      await deleteParticipant(element);
    });
  }

  Future<int> updateParticipantRole(
    String conversationId,
    String participantId,
    ParticipantRole? role,
  ) =>
      (update(db.participants)..where(
            (tbl) =>
                tbl.conversationId.equals(conversationId) &
                tbl.userId.equals(participantId),
          ))
          .write(ParticipantsCompanion(role: Value(role)))
          .then((value) {
            DataBaseEventBus.instance.updateParticipant([
              MiniParticipantItem(
                conversationId: conversationId,
                userId: participantId,
              ),
            ]);
            return value;
          });

  Future replaceAll(String conversationId, List<Participant> list) async =>
      transaction(() async {
        await _deleteByConversationId(conversationId);
        await insertAll(list);
      }).then((value) {
        DataBaseEventBus.instance.updateParticipant(
          list.map(
            (participant) => MiniParticipantItem(
              conversationId: participant.conversationId,
              userId: participant.userId,
            ),
          ),
        );
      });

  Future _deleteByConversationId(String conversationId) async {
    await (delete(
      db.participants,
    )..where((tbl) => tbl.conversationId.equals(conversationId))).go();
  }

  Future deleteByCIdAndPId(String conversationId, String participantId) async =>
      (delete(db.participants)..where(
            (tbl) =>
                tbl.conversationId.equals(conversationId) &
                tbl.userId.equals(participantId),
          ))
          .go()
          .then((value) {
            DataBaseEventBus.instance.updateParticipant([
              MiniParticipantItem(
                conversationId: conversationId,
                userId: participantId,
              ),
            ]);
            return value;
          });

  Selectable<Participant> participantById(
    String conversationId,
    String userId,
  ) => (db.select(db.participants)
    ..where(
      (tbl) =>
          tbl.conversationId.equals(conversationId) & tbl.userId.equals(userId),
    ));

  Future<List<Participant>> getAllParticipants({
    required int limit,
    required int offset,
  }) async {
    final query = select(db.participants)
      ..orderBy([(t) => OrderingTerm.asc(t.rowId)])
      ..limit(limit, offset: offset);
    return query.get();
  }
}
