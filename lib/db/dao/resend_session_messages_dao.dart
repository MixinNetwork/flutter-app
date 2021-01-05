import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'resend_session_messages_dao.g.dart';

@UseDao(tables: [ResendSessionMessages])
class ResendSessionMessagesDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesHistoryDaoMixin {
  ResendSessionMessagesDao(MixinDatabase db) : super(db);
}
