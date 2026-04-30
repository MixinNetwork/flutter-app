import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/ai/ai_chat_prompt_builder.dart';
import 'package:flutter_app/ai/ai_message_context.dart';
import 'package:flutter_app/ai/tools/ai_conversation_tool_service.dart';
import 'package:flutter_app/db/ai_database.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/extension/message.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:toon_format/toon_format.dart';

void main() {
  group('AI conversation context', () {
    late MixinDatabase mixinDatabase;
    late FtsDatabase ftsDatabase;
    late AiDatabase aiDatabase;
    late Database database;

    setUp(() async {
      mixinDatabase = MixinDatabase(NativeDatabase.memory());
      ftsDatabase = FtsDatabase(NativeDatabase.memory());
      aiDatabase = AiDatabase(NativeDatabase.memory());
      database = Database(mixinDatabase, ftsDatabase, aiDatabase);

      await _insertUser(database, 'owner', 'Owner');
      await _insertUser(database, 'alice', 'Alice');
      await _insertUser(database, 'bob', 'Bob');
      await database.mixinDatabase
          .into(database.mixinDatabase.conversations)
          .insert(
            ConversationsCompanion.insert(
              conversationId: 'conversation',
              ownerId: const Value('owner'),
              createdAt: DateTime(2026, 4, 30, 9),
              status: ConversationStatus.success,
            ),
          );
    });

    tearDown(() async {
      await database.dispose();
    });

    test('message context line includes quoted message content', () async {
      final createdAt = DateTime(2026, 4, 30, 9, 1);
      await _insertMessage(
        database,
        id: 'quoted',
        userId: 'bob',
        content: 'quoted topic detail',
        createdAt: createdAt,
      );
      final quote = await database.messageDao.findMessageItemById(
        'conversation',
        'quoted',
      );
      await _insertMessage(
        database,
        id: 'reply',
        userId: 'alice',
        content: 'replying to that',
        createdAt: createdAt.add(const Duration(minutes: 1)),
        quoteMessageId: 'quoted',
        quoteContent: quote!.toJson(),
      );

      final reply = await database.messageDao
          .messageItemByMessageId('reply')
          .getSingle();

      expect(
        aiMessageContextLine(reply),
        contains('quoted_message:'),
      );
      expect(aiMessageContextLine(reply), contains('Bob (message_id=quoted)'));
      expect(aiMessageContextLine(reply), contains('quoted topic detail'));
    });

    test('search results include nearby and quote-linked messages', () async {
      final createdAt = DateTime(2026, 4, 30, 10);
      await _insertMessage(
        database,
        id: 'before',
        userId: 'alice',
        content: 'setup before topic',
        createdAt: createdAt,
      );
      await _insertMessage(
        database,
        id: 'target',
        userId: 'bob',
        content: 'alpha decision',
        createdAt: createdAt.add(const Duration(minutes: 1)),
      );
      await _insertMessage(
        database,
        id: 'after',
        userId: 'alice',
        content: 'follow up detail',
        createdAt: createdAt.add(const Duration(minutes: 2)),
      );
      final quote = await database.messageDao.findMessageItemById(
        'conversation',
        'target',
      );
      await _insertMessage(
        database,
        id: 'quote-reply',
        userId: 'alice',
        content: 'reply via quote',
        createdAt: createdAt.add(const Duration(minutes: 3)),
        quoteMessageId: 'target',
        quoteContent: quote!.toJson(),
      );

      final service = DatabaseAiConversationToolService(database);
      final targetResult = await service.searchConversationMessages(
        conversationId: 'conversation',
        query: 'alpha',
        limit: 1,
      );
      final targetJson = targetResult.toJson();
      expect(encode(targetJson), contains('context_messages'));
      final targetMessage =
          (targetJson['messages'] as List).single as Map<String, dynamic>;

      expect(targetMessage['message_id'], 'target');
      expect(
        targetMessage['context_messages'],
        contains(containsPair('message_id', 'before')),
      );
      expect(
        targetMessage['context_messages'],
        contains(containsPair('message_id', 'after')),
      );
      expect(
        targetMessage['quoted_by_messages'],
        contains(containsPair('message_id', 'quote-reply')),
      );

      final quoteResult = await service.searchConversationMessages(
        conversationId: 'conversation',
        query: 'quote',
        limit: 1,
      );
      final quoteJson = quoteResult.toJson();
      final quoteMessage =
          (quoteJson['messages'] as List).single as Map<String, dynamic>;

      expect(quoteMessage['message_id'], 'quote-reply');
      expect(
        quoteMessage['quoted_message'],
        containsPair('message_id', 'target'),
      );
    });

    test(
      'attached transcript prompt includes focused transcript items',
      () async {
        final createdAt = DateTime(2026, 4, 30, 11);
        await _insertMessage(
          database,
          id: 'before-transcript',
          userId: 'alice',
          content: 'noise before transcript',
          createdAt: createdAt,
        );
        await _insertMessage(
          database,
          id: 'transcript',
          userId: 'bob',
          content: '[Transcript]',
          createdAt: createdAt.add(const Duration(minutes: 1)),
          category: MessageCategory.plainTranscript,
        );
        await _insertMessage(
          database,
          id: 'after-transcript',
          userId: 'alice',
          content: 'noise after transcript',
          createdAt: createdAt.add(const Duration(minutes: 2)),
        );
        await database.mixinDatabase
            .into(database.mixinDatabase.transcriptMessages)
            .insert(
              TranscriptMessagesCompanion.insert(
                transcriptId: 'transcript',
                messageId: 'transcript-item-1',
                category: MessageCategory.plainText,
                createdAt: createdAt.add(const Duration(minutes: 3)),
                content: const Value('real transcript detail'),
                userId: const Value('alice'),
                userFullName: const Value('Alice'),
              ),
            );

        final attached = await database.messageDao
            .messageItemByMessageId('transcript')
            .getSingle();
        final promptMessages = await AiChatPromptBuilder(database)
            .buildPromptMessages(
              'conversation',
              'thread',
              'what is inside this transcript?',
              'English',
              attachedMessages: [attached],
            );
        final prompt = promptMessages
            .map((message) => message.content)
            .join('\n');

        expect(prompt, contains('Primary attached message:'));
        expect(prompt, contains('relation=attached_primary'));
        expect(prompt, contains('Attached transcript messages:'));
        expect(prompt, contains('real transcript detail'));
        expect(
          prompt,
          contains('Nearby context messages, for disambiguation only'),
        );
        expect(prompt, contains('noise before transcript'));
      },
    );
  });
}

Future<void> _insertUser(Database database, String id, String name) => database
    .mixinDatabase
    .into(database.mixinDatabase.users)
    .insert(
      UsersCompanion.insert(
        userId: id,
        identityNumber: id,
        fullName: Value(name),
      ),
    );

Future<void> _insertMessage(
  Database database, {
  required String id,
  required String userId,
  required String content,
  required DateTime createdAt,
  String category = MessageCategory.plainText,
  String? quoteMessageId,
  String? quoteContent,
}) async {
  await database.mixinDatabase
      .into(database.mixinDatabase.messages)
      .insert(
        MessagesCompanion.insert(
          messageId: id,
          conversationId: 'conversation',
          userId: userId,
          category: category,
          content: Value(content),
          status: MessageStatus.read,
          createdAt: createdAt,
          quoteMessageId: Value(quoteMessageId),
          quoteContent: Value(quoteContent),
        ),
      );

  final rowId = await database.ftsDatabase
      .into(database.ftsDatabase.messagesFts)
      .insert(MessagesFt(content: content));
  await database.ftsDatabase
      .into(database.ftsDatabase.messagesMetas)
      .insert(
        MessagesMeta(
          docId: rowId,
          messageId: id,
          conversationId: 'conversation',
          category: category,
          userId: userId,
          createdAt: createdAt,
        ),
      );
}
