import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'participants_dao.g.dart';

@UseDao(tables: [Participants])
class ParticipantsDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesHistoryDaoMixin {
  ParticipantsDao(MixinDatabase db) : super(db);
}
