import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'participant_session_dao.g.dart';

@UseDao(tables: [ParticipantSession])
class ParticipantSessionDao extends DatabaseAccessor<MixinDatabase>
    with _$ParticipantSessionDaoMixin {
  ParticipantSessionDao(MixinDatabase db) : super(db);

  Future<int> insert(ParticipantSessionData participantSession) =>
      into(db.participantSession).insert(participantSession);

  Future deleteParticipantSession(ParticipantSessionData participantSession) =>
      delete(db.participantSession).delete(participantSession);
}
