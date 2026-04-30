import 'package:mixin_logger/mixin_logger.dart';

import '../db/dao/transcript_message_dao.dart';
import '../db/database.dart';
import '../db/extension/message_category.dart';
import '../db/mixin_database.dart';
import 'ai_message_context.dart';
import 'model/ai_prompt_message.dart';
import 'model/ai_prompt_template.dart';

class AiChatPromptBuilder {
  AiChatPromptBuilder(this.database);

  static const _aiStatusPending = 'pending';
  static const _aiContextMessageLimit = 30;
  static const _aiHistoryLimit = 12;
  static const _attachedContextBeforeLimit = 2;
  static const _attachedContextAfterLimit = 2;
  static const _attachedQuotedByLimit = 3;
  static const _attachedContextMaxTextLength = 1000;
  static const _attachedTranscriptLimit = 80;
  static const _attachedTranscriptMaxTextLength = 800;

  final Database database;

  Future<List<AiPromptMessage>> buildPromptMessages(
    String conversationId,
    String threadId,
    String input,
    String language, {
    String? currentMessageId,
    List<MessageItem> attachedMessages = const [],
  }) async {
    final now = DateTime.now();
    final recentMessages = await database.messageDao
        .messagesByConversationId(conversationId, _aiContextMessageLimit)
        .get();
    final aiMessages = await database.aiChatMessageDao.threadMessages(threadId);

    final promptMessages = <AiPromptMessage>[
      ..._promptMessages(
        role: AiPromptRole.system,
        content: renderAiPromptTemplate(
          database.settingProperties.aiPromptTemplate(
            AiPromptTemplateKey.chatSystem,
          ),
          buildAiPromptTemplateVariables(
            conversationId: conversationId,
            input: input,
            language: language,
            now: now,
          ),
        ),
      ),
    ];

    _appendConversationToolInstruction(
      promptMessages,
      enabled: true,
      conversationId: conversationId,
      language: language,
      now: now,
    );
    _appendConversationContext(
      promptMessages,
      conversationId: conversationId,
      recentMessages: recentMessages,
      language: language,
      now: now,
    );
    await _appendAttachedMessages(
      promptMessages,
      attachedMessages: attachedMessages,
      language: language,
      now: now,
    );

    final history = aiMessages
        .where(
          (element) =>
              element.status != _aiStatusPending &&
              element.id != currentMessageId,
        )
        .takeLast(_aiHistoryLimit);
    for (final item in history) {
      promptMessages.add(
        AiPromptMessage(role: AiPromptRole(item.role), content: item.content),
      );
    }

    promptMessages.addAll(
      _promptMessages(
        role: AiPromptRole.user,
        content: renderAiPromptTemplate(
          chatUserMessagePromptTemplate,
          buildAiPromptTemplateVariables(
            conversationId: conversationId,
            input: input,
            language: language,
            now: now,
          ),
        ),
      ),
    );
    d(
      'AI prompt built: conversationId=$conversationId '
      'threadId=$threadId '
      'recent=${recentMessages.length} '
      'attached=${attachedMessages.length} '
      'history=${history.length} promptMessages=${promptMessages.length}',
    );
    return promptMessages;
  }

  Future<List<AiPromptMessage>> buildAssistPromptMessages({
    required String instruction,
    required String? input,
    required String? conversationId,
    required String language,
  }) async {
    final now = DateTime.now();
    final inputText = input?.trim();
    final trimmedInstruction = instruction.trim();
    final promptMessages = <AiPromptMessage>[
      ..._promptMessages(
        role: AiPromptRole.system,
        content: renderAiPromptTemplate(
          database.settingProperties.aiPromptTemplate(
            AiPromptTemplateKey.assistSystem,
          ),
          buildAiPromptTemplateVariables(
            conversationId: conversationId,
            input: inputText,
            instruction: trimmedInstruction,
            inputSection: buildAiPromptInputSection(inputText),
            language: language,
            now: now,
          ),
        ),
      ),
    ];

    if (conversationId != null) {
      _appendConversationToolInstruction(
        promptMessages,
        enabled: true,
        conversationId: conversationId,
        language: language,
        now: now,
      );
      final recentMessages = await database.messageDao
          .messagesByConversationId(conversationId, _aiContextMessageLimit)
          .get();
      _appendConversationContext(
        promptMessages,
        conversationId: conversationId,
        recentMessages: recentMessages,
        language: language,
        now: now,
      );
    }

    promptMessages.addAll(
      _promptMessages(
        role: AiPromptRole.user,
        content: renderAiPromptTemplate(
          assistUserMessagePromptTemplate,
          buildAiPromptTemplateVariables(
            conversationId: conversationId,
            input: inputText,
            instruction: trimmedInstruction,
            inputSection: buildAiPromptInputSection(inputText),
            language: language,
            now: now,
          ),
        ),
      ),
    );
    d(
      'AI assist prompt built: conversationId=$conversationId '
      'messages=${promptMessages.length}',
    );
    return promptMessages;
  }

  void _appendConversationToolInstruction(
    List<AiPromptMessage> promptMessages, {
    required bool enabled,
    required String? conversationId,
    required String language,
    required DateTime now,
  }) {
    if (!enabled) {
      return;
    }
    promptMessages.addAll(
      _promptMessages(
        role: AiPromptRole.system,
        content: renderAiPromptTemplate(
          conversationToolInstructionPromptTemplate,
          buildAiPromptTemplateVariables(
            conversationId: conversationId,
            language: language,
            now: now,
          ),
        ),
      ),
    );
  }

  void _appendConversationContext(
    List<AiPromptMessage> promptMessages, {
    required String conversationId,
    required List<MessageItem> recentMessages,
    required String language,
    required DateTime now,
  }) {
    if (recentMessages.isNotEmpty) {
      final lines = recentMessages.reversed
          .map(
            (message) => aiMessageContextLine(
              message,
              relation: 'recent',
              maxTextLength: _attachedContextMaxTextLength,
            ),
          )
          .join('\n');
      promptMessages.addAll(
        _promptMessages(
          role: AiPromptRole.system,
          content: renderAiPromptTemplate(
            recentConversationContextPromptTemplate,
            buildAiPromptTemplateVariables(
              conversationId: conversationId,
              messages: lines,
              language: language,
              now: now,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _appendAttachedMessages(
    List<AiPromptMessage> promptMessages, {
    required List<MessageItem> attachedMessages,
    required String language,
    required DateTime now,
  }) async {
    if (attachedMessages.isEmpty) {
      return;
    }

    final blocks = <String>[];
    for (final message in attachedMessages) {
      blocks.add(await _attachedMessageContextBlock(message));
    }
    promptMessages.addAll(
      _promptMessages(
        role: AiPromptRole.system,
        content:
            'User-attached messages for the next request. Treat these as '
            'the primary quoted context, especially when the user says '
            '"this message", "these messages", or asks for a specific '
            'message to be handled. Answer in $language unless the user '
            'explicitly asks for another language. Current time: '
            '${now.toIso8601String()}.\n\n${blocks.join('\n\n')}',
      ),
    );
  }

  Future<String> _attachedMessageContextBlock(MessageItem message) async {
    final contextMessages = await _messageContextWindow(
      message,
      beforeLimit: _attachedContextBeforeLimit,
      afterLimit: _attachedContextAfterLimit,
    );
    final lines = <String>[
      'Attached context block for message_id=${message.messageId}:',
      'Primary attached message:',
      aiMessageContextLine(
        message,
        relation: 'attached_primary',
        maxTextLength: _attachedContextMaxTextLength,
      ),
    ];

    final missingQuoteLine = await _missingQuoteContextLine(message);
    if (missingQuoteLine != null) {
      lines.add('  $missingQuoteLine');
    }

    if (message.type.isTranscript) {
      final transcriptLines = await _attachedTranscriptContextLines(message);
      if (transcriptLines.isNotEmpty) {
        lines
          ..add('Attached transcript messages:')
          ..addAll(transcriptLines);
      }
    }

    final nearbyMessages = contextMessages
        .where(
          (contextMessage) => contextMessage.messageId != message.messageId,
        )
        .toList(growable: false);
    if (nearbyMessages.isNotEmpty) {
      lines.add('Nearby context messages, for disambiguation only:');
      for (final contextMessage in nearbyMessages) {
        lines.add(
          aiMessageContextLine(
            contextMessage,
            relation: 'nearby',
            maxTextLength: _attachedContextMaxTextLength,
          ),
        );
      }
    }

    final quotedByMessages = await database.messageDao
        .messagesByQuoteId(
          message.conversationId,
          message.messageId,
          _attachedQuotedByLimit,
        )
        .get();
    if (quotedByMessages.isNotEmpty) {
      lines.add('Messages quoting attached message:');
      for (final quotedByMessage in quotedByMessages) {
        lines.add(
          aiMessageContextLine(
            quotedByMessage,
            relation: 'quotes_attached',
            maxTextLength: _attachedContextMaxTextLength,
          ),
        );
      }
    }

    return lines.join('\n');
  }

  Future<List<String>> _attachedTranscriptContextLines(
    MessageItem message,
  ) async {
    final transcriptMessages = await database.transcriptMessageDao
        .transactionMessageItem(message.messageId)
        .get();
    if (transcriptMessages.isEmpty) {
      return const [];
    }

    return transcriptMessages
        .take(_attachedTranscriptLimit)
        .map(
          (item) => aiMessageContextLine(
            item.messageItem,
            relation: 'attached_transcript_item',
            maxTextLength: _attachedTranscriptMaxTextLength,
          ),
        )
        .toList(growable: false);
  }

  Future<List<MessageItem>> _messageContextWindow(
    MessageItem message, {
    required int beforeLimit,
    required int afterLimit,
  }) async {
    final orderInfo = await database.messageDao.messageOrderInfo(
      message.messageId,
    );
    if (orderInfo == null) {
      return [message];
    }

    final beforeMessages = beforeLimit <= 0
        ? const <MessageItem>[]
        : await database.messageDao
              .beforeMessagesByConversationId(
                orderInfo,
                message.conversationId,
                beforeLimit,
              )
              .get();
    final afterMessages = afterLimit <= 0
        ? const <MessageItem>[]
        : await database.messageDao
              .afterMessagesByConversationId(
                orderInfo,
                message.conversationId,
                afterLimit,
              )
              .get();
    final byMessageId = <String, MessageItem>{};
    for (final item in [
      ...beforeMessages.reversed,
      message,
      ...afterMessages,
    ]) {
      byMessageId[item.messageId] = item;
    }
    return byMessageId.values.toList(growable: false);
  }

  Future<String?> _missingQuoteContextLine(MessageItem message) async {
    if (aiMessageQuotedItem(message) != null) {
      return null;
    }
    final quoteId = message.quoteId?.trim();
    if (quoteId == null || quoteId.isEmpty) {
      return null;
    }
    final quote = await database.messageDao.findMessageItemById(
      message.conversationId,
      quoteId,
    );
    if (quote == null) {
      return 'quoted_message: message_id=$quoteId (not available)';
    }
    return aiQuoteMessageContextLine(quote);
  }

  List<AiPromptMessage> _promptMessages({
    required AiPromptRole role,
    required String content,
  }) {
    if (content.trim().isEmpty) {
      return const [];
    }
    return [AiPromptMessage(role: role, content: content)];
  }
}

extension _IterableTakeLastExtension<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    if (count <= 0) return const [];
    final list = toList();
    if (list.length <= count) {
      return list;
    }
    return list.sublist(list.length - count);
  }
}
