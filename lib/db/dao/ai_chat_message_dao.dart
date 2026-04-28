import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../ai/model/ai_chat_metadata.dart';
import '../ai_database.dart';

part 'ai_chat_message_dao.g.dart';

@DriftAccessor()
class AiChatMessageDao extends DatabaseAccessor<AiDatabase>
    with _$AiChatMessageDaoMixin {
  AiChatMessageDao(super.db);

  static const assistantRole = 'assistant';
  static const pendingStatus = 'pending';
  static const errorStatus = 'error';
  static const _uuid = Uuid();

  Stream<AiChatThread?> watchLatestThread(String conversationId) =>
      (select(db.aiChatThreads)
            ..where((tbl) => tbl.conversationId.equals(conversationId))
            ..orderBy([
              (tbl) => OrderingTerm.desc(tbl.updatedAt),
              (tbl) => OrderingTerm.desc(tbl.createdAt),
              (tbl) => OrderingTerm.desc(tbl.id),
            ])
            ..limit(1))
          .watchSingleOrNull();

  Future<AiChatThread?> latestThread(String conversationId) =>
      (select(db.aiChatThreads)
            ..where((tbl) => tbl.conversationId.equals(conversationId))
            ..orderBy([
              (tbl) => OrderingTerm.desc(tbl.updatedAt),
              (tbl) => OrderingTerm.desc(tbl.createdAt),
              (tbl) => OrderingTerm.desc(tbl.id),
            ])
            ..limit(1))
          .getSingleOrNull();

  Future<AiChatThread?> threadById(String threadId) => (select(
    db.aiChatThreads,
  )..where((tbl) => tbl.id.equals(threadId))).getSingleOrNull();

  Future<AiChatThread> createThread(String conversationId) async {
    final now = DateTime.now();
    final thread = AiChatThread(
      id: _uuid.v4(),
      conversationId: conversationId,
      createdAt: now,
      updatedAt: now,
    );
    await into(db.aiChatThreads).insert(thread);
    return thread;
  }

  Future<AiChatThread> ensureThread({
    required String conversationId,
    String? threadId,
  }) async {
    if (threadId != null) {
      final thread = await threadById(threadId);
      if (thread == null || thread.conversationId != conversationId) {
        throw StateError('AI thread not found');
      }
      return thread;
    }

    final existing = await latestThread(conversationId);
    if (existing != null) return existing;
    return createThread(conversationId);
  }

  Stream<List<AiChatMessage>> watchThreadMessages(String threadId) =>
      (select(
              db.aiChatMessages,
            )
            ..where((tbl) => tbl.threadId.equals(threadId))
            ..orderBy([
              (tbl) => OrderingTerm.asc(tbl.createdAt),
              (tbl) => OrderingTerm.asc(tbl.id),
            ]))
          .watch();

  Stream<List<AiChatMessage>> watchLatestThreadMessages(
    String threadId,
    int limit,
  ) =>
      (select(
              db.aiChatMessages,
            )
            ..where((tbl) => tbl.threadId.equals(threadId))
            ..orderBy([
              (tbl) => OrderingTerm.desc(tbl.createdAt),
              (tbl) => OrderingTerm.desc(tbl.id),
            ])
            ..limit(limit))
          .watch()
          .map((items) => items.reversed.toList(growable: false));

  Future<List<AiChatMessage>> threadMessages(String threadId) =>
      (select(
              db.aiChatMessages,
            )
            ..where((tbl) => tbl.threadId.equals(threadId))
            ..orderBy([
              (tbl) => OrderingTerm.asc(tbl.createdAt),
              (tbl) => OrderingTerm.asc(tbl.id),
            ]))
          .get();

  Future<List<AiChatMessage>> beforeThreadMessages({
    required String threadId,
    required AiChatMessage before,
    required int limit,
  }) async {
    final beforeCreatedAt = before.createdAt.millisecondsSinceEpoch;
    final list =
        await (select(
                db.aiChatMessages,
              )
              ..where(
                (tbl) =>
                    tbl.threadId.equals(threadId) &
                    (tbl.createdAt.isSmallerThanValue(beforeCreatedAt) |
                        (tbl.createdAt.equals(beforeCreatedAt) &
                            tbl.id.isSmallerThanValue(before.id))),
              )
              ..orderBy([
                (tbl) => OrderingTerm.desc(tbl.createdAt),
                (tbl) => OrderingTerm.desc(tbl.id),
              ])
              ..limit(limit))
            .get();
    return list.reversed.toList(growable: false);
  }

  Future<void> insertMessage(AiChatMessagesCompanion row) async {
    await into(db.aiChatMessages).insertOnConflictUpdate(row);
    await _touchThread(row.threadId.value);
  }

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

  Future<void> appendMessageMetadataToolEvent(
    String id,
    Map<String, dynamic> event, {
    required DateTime updatedAt,
  }) async {
    await transaction(() async {
      final message = await (select(
        db.aiChatMessages,
      )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
      if (message == null) {
        return;
      }
      final metadata = appendAiToolEventToMetadata(message.metadata, event);
      await (update(
        db.aiChatMessages,
      )..where((tbl) => tbl.id.equals(id))).write(
        AiChatMessagesCompanion(
          metadata: Value(metadata),
          updatedAt: Value(updatedAt),
        ),
      );
    });
  }

  Future<void> setMessageMetadataResponse(
    String id,
    Map<String, dynamic> responseMetadata, {
    required DateTime updatedAt,
  }) async {
    await transaction(() async {
      final message = await (select(
        db.aiChatMessages,
      )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
      if (message == null) {
        return;
      }
      final metadata = setAiResponseMetadata(
        message.metadata,
        responseMetadata,
      );
      await (update(
        db.aiChatMessages,
      )..where((tbl) => tbl.id.equals(id))).write(
        AiChatMessagesCompanion(
          metadata: Value(metadata),
          updatedAt: Value(updatedAt),
        ),
      );
    });
  }

  Future<void> deleteConversationMessages(String conversationId) => (delete(
    db.aiChatMessages,
  )..where((tbl) => tbl.conversationId.equals(conversationId))).go();

  Future<bool> hasPendingAssistantMessage(
    String threadId, {
    DateTime? updatedAfter,
  }) async {
    final query = selectOnly(db.aiChatMessages)
      ..addColumns([db.aiChatMessages.id.count()])
      ..where(
        db.aiChatMessages.threadId.equals(threadId) &
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
    String? threadId,
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
                : tbl.conversationId.equals(conversationId)) &
            (threadId == null
                ? const Constant(true)
                : tbl.threadId.equals(threadId)),
      );
    return query.write(
      AiChatMessagesCompanion(
        status: const Value(errorStatus),
        errorText: Value(errorText),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _touchThread(String threadId) =>
      (update(
        db.aiChatThreads,
      )..where((tbl) => tbl.id.equals(threadId))).write(
        AiChatThreadsCompanion(updatedAt: Value(DateTime.now())),
      );
}
