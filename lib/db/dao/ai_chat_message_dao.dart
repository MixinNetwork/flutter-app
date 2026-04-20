import 'package:drift/drift.dart';

import '../mixin_database.dart';

part 'ai_chat_message_dao.g.dart';

@DriftAccessor()
class AiChatMessageDao extends DatabaseAccessor<MixinDatabase>
    with _$AiChatMessageDaoMixin {
  AiChatMessageDao(super.db);

  static const assistantRole = 'assistant';
  static const pendingStatus = 'pending';
  static const errorStatus = 'error';

  Stream<List<AiChatMessage>> watchConversationMessages(
    String conversationId,
  ) =>
      (select(
              db.aiChatMessages,
            )
            ..where((tbl) => tbl.conversationId.equals(conversationId))
            ..orderBy([
              (tbl) => OrderingTerm.asc(tbl.createdAt),
              (tbl) => OrderingTerm.asc(tbl.id),
            ]))
          .watch();

  Future<List<AiChatMessage>> conversationMessages(String conversationId) =>
      (select(
              db.aiChatMessages,
            )
            ..where((tbl) => tbl.conversationId.equals(conversationId))
            ..orderBy([
              (tbl) => OrderingTerm.asc(tbl.createdAt),
              (tbl) => OrderingTerm.asc(tbl.id),
            ]))
          .get();

  Future<void> insertMessage(AiChatMessagesCompanion row) =>
      into(db.aiChatMessages).insertOnConflictUpdate(row);

  Future<void> updateMessageContent(
    String id,
    String content, {
    required DateTime updatedAt,
  }) => (update(db.aiChatMessages)..where((tbl) => tbl.id.equals(id))).write(
    AiChatMessagesCompanion(
      content: Value(content),
      updatedAt: Value(updatedAt),
    ),
  );

  Future<void> updateMessageStatus(
    String id,
    String status, {
    required DateTime updatedAt,
    String? errorText,
  }) => (update(db.aiChatMessages)..where((tbl) => tbl.id.equals(id))).write(
    AiChatMessagesCompanion(
      status: Value(status),
      errorText: Value(errorText),
      updatedAt: Value(updatedAt),
    ),
  );

  Future<void> deleteConversationMessages(String conversationId) => (delete(
    db.aiChatMessages,
  )..where((tbl) => tbl.conversationId.equals(conversationId))).go();

  Future<bool> hasPendingAssistantMessage(
    String conversationId, {
    DateTime? updatedAfter,
  }) async {
    final query = selectOnly(db.aiChatMessages)
      ..addColumns([db.aiChatMessages.id.count()])
      ..where(
        db.aiChatMessages.conversationId.equals(conversationId) &
            db.aiChatMessages.role.equals(assistantRole) &
            db.aiChatMessages.status.equals(pendingStatus) &
            (updatedAfter == null
                ? const Constant(true)
                : db.aiChatMessages.updatedAt.isBiggerOrEqualValue(
                    updatedAfter.millisecondsSinceEpoch,
                  )),
      );
    final row = await query.getSingleOrNull();
    final count = row?.read(db.aiChatMessages.id.count()) ?? 0;
    return count > 0;
  }

  Future<int> resolveStalePendingAssistantMessages({
    required DateTime updatedBefore,
    String? conversationId,
    String errorText = 'Interrupted by app restart',
  }) {
    final query = update(db.aiChatMessages)
      ..where(
        (tbl) =>
            tbl.role.equals(assistantRole) &
            tbl.status.equals(pendingStatus) &
            tbl.updatedAt.isSmallerThanValue(
              updatedBefore.millisecondsSinceEpoch,
            ) &
            (conversationId == null
                ? const Constant(true)
                : tbl.conversationId.equals(conversationId)),
      );
    return query.write(
      AiChatMessagesCompanion(
        status: const Value(errorStatus),
        errorText: Value(errorText),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
