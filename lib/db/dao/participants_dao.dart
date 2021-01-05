import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'participants_dao.g.dart';

@UseDao(tables: [Participants])
class ParticipantsDao extends DatabaseAccessor<MixinDatabase>
    with _$ParticipantsDaoMixin {
  ParticipantsDao(MixinDatabase db) : super(db);

  Future<int> insert(Participant participant) =>
      into(db.participants).insert(participant);

  Future deleteParticipant(Participant participant) =>
      delete(db.participants).delete(participant);
}
