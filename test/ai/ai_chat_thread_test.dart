import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/ai/ai_chat_prompt_builder.dart';
import 'package:flutter_app/ai/model/ai_prompt_message.dart';
import 'package:flutter_app/db/ai_database.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AI chat threads', () {
    late MixinDatabase mixinDatabase;
    late FtsDatabase ftsDatabase;
    late AiDatabase aiDatabase;
    late Database database;

    setUp(() {
      mixinDatabase = MixinDatabase(NativeDatabase.memory());
      ftsDatabase = FtsDatabase(NativeDatabase.memory());
      aiDatabase = AiDatabase(NativeDatabase.memory());
      database = Database(mixinDatabase, ftsDatabase, aiDatabase);
    });

    tearDown(() => database.dispose());

    test('scopes messages and pending state by thread', () async {
      const conversationId = 'conversation-id';
      final firstThread = await database.aiChatMessageDao.createThread(
        conversationId,
      );
      final secondThread = await database.aiChatMessageDao.createThread(
        conversationId,
      );
      final now = DateTime.now();

      await database.aiChatMessageDao.insertMessage(
        AiChatMessagesCompanion.insert(
          id: 'first-thread-message',
          threadId: Value(firstThread.id),
          conversationId: conversationId,
          role: 'assistant',
          providerId: 'provider-id',
          content: 'pending in first thread',
          status: 'pending',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await database.aiChatMessageDao.insertMessage(
        AiChatMessagesCompanion.insert(
          id: 'second-thread-message',
          threadId: Value(secondThread.id),
          conversationId: conversationId,
          role: 'user',
          providerId: 'provider-id',
          content: 'done in second thread',
          status: 'done',
          createdAt: now.add(const Duration(milliseconds: 1)),
          updatedAt: now.add(const Duration(milliseconds: 1)),
        ),
      );

      final firstMessages = await database.aiChatMessageDao.threadMessages(
        firstThread.id,
      );
      final secondMessages = await database.aiChatMessageDao.threadMessages(
        secondThread.id,
      );

      expect(firstMessages.map((item) => item.id), ['first-thread-message']);
      expect(secondMessages.map((item) => item.id), ['second-thread-message']);
      expect(
        await database.aiChatMessageDao.hasPendingAssistantMessage(
          firstThread.id,
        ),
        isTrue,
      );
      expect(
        await database.aiChatMessageDao.hasPendingAssistantMessage(
          secondThread.id,
        ),
        isFalse,
      );
    });

    test('prompt history excludes the current user message', () async {
      const conversationId = 'conversation-id';
      final thread = await database.aiChatMessageDao.createThread(
        conversationId,
      );
      final now = DateTime.now();

      await database.aiChatMessageDao.insertMessage(
        AiChatMessagesCompanion.insert(
          id: 'previous-message',
          threadId: Value(thread.id),
          conversationId: conversationId,
          role: 'assistant',
          providerId: 'provider-id',
          content: 'previous answer',
          status: 'done',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await database.aiChatMessageDao.insertMessage(
        AiChatMessagesCompanion.insert(
          id: 'current-message',
          threadId: Value(thread.id),
          conversationId: conversationId,
          role: 'user',
          providerId: 'provider-id',
          content: 'current question',
          status: 'done',
          createdAt: now.add(const Duration(milliseconds: 1)),
          updatedAt: now.add(const Duration(milliseconds: 1)),
        ),
      );

      final messages = await AiChatPromptBuilder(database).buildPromptMessages(
        conversationId,
        thread.id,
        'current question',
        'en',
        currentMessageId: 'current-message',
      );

      expect(
        messages.where(
          (item) =>
              item.role.value == AiPromptRole.user.value &&
              item.content.contains('current question'),
        ),
        hasLength(1),
      );
      expect(
        messages.where((item) => item.content == 'previous answer'),
        hasLength(1),
      );
    });
  });
}
