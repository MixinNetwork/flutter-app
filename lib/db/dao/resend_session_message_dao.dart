import 'package:drift/drift.dart';

import '../mixin_database.dart';

part 'resend_session_message_dao.g.dart';

@DriftAccessor()
class ResendSessionMessageDao extends DatabaseAccessor<MixinDatabase>
    with _$ResendSessionMessageDaoMixin {
  ResendSessionMessageDao(super.db);

  Future<int> insert(ResendSessionMessage resendSessionMessage) => into(
    db.resendSessionMessages,
  ).insertOnConflictUpdate(resendSessionMessage);

  Future<int> deleteResendSessionMessageById(String messageId) =>
      (delete(db.resendSessionMessages)
        ..where((tbl) => tbl.messageId.equals(messageId))).go();

  Future<ResendSessionMessage?> findResendMessage(
    String userId,
    String sessionId,
    String messageId,
  ) async =>
      (select(db.resendSessionMessages)..where(
        (tbl) =>
            tbl.userId.equals(userId) &
            tbl.sessionId.equals(sessionId) &
            tbl.messageId.equals(messageId),
      )).getSingleOrNull();
}
