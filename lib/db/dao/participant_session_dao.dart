import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'participant_session_dao.g.dart';

@UseDao(tables: [ParticipantSession])
class ParticipantSessionDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesHistoryDaoMixin {
  ParticipantSessionDao(MixinDatabase db) : super(db);
}
