import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'participant_session_dao.g.dart';

@UseDao(tables: [ParticipantSession])
class ParticipantSessionDao extends DatabaseAccessor<MixinDatabase>
    with _$ParticipantSessionDaoMixin {
  ParticipantSessionDao(MixinDatabase db) : super(db);

  Future<int> insert(ParticipantSessionData participantSession) =>
      into(db.participantSession).insertOnConflictUpdate(participantSession);

  Future deleteParticipantSession(ParticipantSessionData participantSession) =>
      delete(db.participantSession).delete(participantSession);

  Future<ParticipantSessionKey?> getParticipantSessionKeyWithoutSelf(
          String conversationId, String userId) =>
      db
          .getParticipantSessionKeyWithoutSelf(conversationId, userId)
          .getSingle();
}
