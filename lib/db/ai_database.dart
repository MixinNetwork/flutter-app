import 'package:drift/drift.dart';

import 'converter/millis_date_converter.dart';
import 'dao/ai_chat_message_dao.dart';
import 'util/open_database.dart';

part 'ai_database.g.dart';

@DriftDatabase(
  include: {'moor/ai.drift'},
  daos: [AiChatMessageDao],
)
class AiDatabase extends _$AiDatabase {
  AiDatabase(super.e);

  static Future<AiDatabase> connect(
    String identityNumber, {
    bool fromMainIsolate = false,
  }) async {
    final queryExecutor = await openQueryExecutor(
      identityNumber: identityNumber,
      dbName: 'ai',
      readCount: 4,
      fromMainIsolate: fromMainIsolate,
    );
    return AiDatabase(queryExecutor);
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from <= 1) {
        await _addColumnIfNotExists(m, aiChatThreads, aiChatThreads.summary);
        await _addColumnIfNotExists(
          m,
          aiChatThreads,
          aiChatThreads.lastMessagePreview,
        );
        await _addColumnIfNotExists(
          m,
          aiChatThreads,
          aiChatThreads.messageCount,
        );
        await _addColumnIfNotExists(m, aiChatThreads, aiChatThreads.status);
        await _addColumnIfNotExists(m, aiChatThreads, aiChatThreads.pinnedAt);
        await _addColumnIfNotExists(m, aiChatThreads, aiChatThreads.archivedAt);
        await _addColumnIfNotExists(
          m,
          aiChatThreads,
          aiChatThreads.lastMessageAt,
        );
        await _addColumnIfNotExists(m, aiChatThreads, aiChatThreads.metadata);
        await _backfillThreadStats();
        await customStatement(
          'DROP INDEX IF EXISTS index_ai_chat_threads_conversation_id_updated_at',
        );
        await m.createIndex(indexAiChatThreadsConversationIdUpdatedAt);
        await m.createIndex(indexAiChatThreadsConversationIdLastMessageAt);
      }
    },
  );

  Future<void> _addColumnIfNotExists(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    if (!await _checkColumnExists(table.actualTableName, column.name)) {
      await m.addColumn(table, column);
    }
  }

  Future<bool> _checkColumnExists(String tableName, String columnName) async {
    final queryRow = await customSelect(
      "SELECT COUNT(*) AS CNTREC FROM pragma_table_info('$tableName') WHERE name='$columnName'",
    ).getSingle();
    return queryRow.read<bool>('CNTREC');
  }

  Future<void> _backfillThreadStats() async {
    await customStatement('''
UPDATE ai_chat_threads
SET
  message_count = (
    SELECT COUNT(*)
    FROM ai_chat_messages
    WHERE ai_chat_messages.thread_id = ai_chat_threads.id
  ),
  last_message_at = (
    SELECT created_at
    FROM ai_chat_messages
    WHERE ai_chat_messages.thread_id = ai_chat_threads.id
    ORDER BY created_at DESC, id DESC
    LIMIT 1
  ),
  last_message_preview = (
    SELECT substr(trim(replace(replace(content, char(10), ' '), char(13), ' ')), 1, 160)
    FROM ai_chat_messages
    WHERE ai_chat_messages.thread_id = ai_chat_threads.id
    ORDER BY created_at DESC, id DESC
    LIMIT 1
  )
''');
  }
}
