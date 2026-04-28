import 'dart:async';

import 'package:mixin_logger/mixin_logger.dart';

import '../db/dao/message_dao.dart';
import '../db/database.dart';
import '../db/mixin_database.dart';
import 'model/ai_prompt_message.dart';
import 'tools/ai_conversation_tool_service.dart';

class AiChatPromptBuilder {
  AiChatPromptBuilder(this.database);

  static const _aiRoleUser = 'user';
  static const _aiStatusPending = 'pending';
  static const _aiContextMessageLimit = 30;
  static const _aiRetrievedMessageLimit = 6;
  static const _aiHistoryLimit = 12;
  static const _aiRetrievalQueryMaxLength = 120;
  static const _aiLogPreviewLength = 240;

  final Database database;

  Future<List<AiPromptMessage>> buildPromptMessages(
    String conversationId,
    String input,
  ) async {
    final recentMessages = await database.messageDao
        .messagesByConversationId(conversationId, _aiContextMessageLimit)
        .get();
    final retrievedMessages = await _retrieveConversationMessages(
      conversationId: conversationId,
      recentMessages: recentMessages,
      query: input,
    );
    final aiMessages = await database.aiChatMessageDao.conversationMessages(
      conversationId,
    );

    final promptMessages = <AiPromptMessage>[
      AiPromptMessage(
        role: 'system',
        content:
            'You are a local AI assistant inside a chat application. '
            'Only use the provided current conversation context. '
            'Help summarize, answer questions about the conversation, '
            'and draft replies. Be concise and practical.',
      ),
    ];

    _appendConversationToolInstruction(promptMessages, enabled: true);
    _appendConversationContext(
      promptMessages,
      recentMessages: recentMessages,
      retrievedMessages: retrievedMessages,
    );

    final history = aiMessages
        .where((element) => element.status != _aiStatusPending)
        .takeLast(_aiHistoryLimit);
    for (final item in history) {
      promptMessages.add(
        AiPromptMessage(role: item.role, content: item.content),
      );
    }

    promptMessages.add(AiPromptMessage(role: _aiRoleUser, content: input));
    d(
      'AI prompt built: conversationId=$conversationId '
      'recent=${recentMessages.length} retrieved=${retrievedMessages.length} '
      'history=${history.length} promptMessages=${promptMessages.length}',
    );
    return promptMessages;
  }

  Future<List<AiPromptMessage>> buildAssistPromptMessages({
    required String instruction,
    required String? input,
    required String? conversationId,
  }) async {
    final promptMessages = <AiPromptMessage>[
      AiPromptMessage(
        role: 'system',
        content:
            'You are an invisible writing assistant inside a chat app. '
            'Return only the requested text. Do not add explanations, '
            'labels, markdown fences, or greetings unless explicitly '
            'requested.',
      ),
    ];

    if (conversationId != null) {
      _appendConversationToolInstruction(promptMessages, enabled: true);
      final recentMessages = await database.messageDao
          .messagesByConversationId(conversationId, _aiContextMessageLimit)
          .get();
      final retrievedMessages = await _retrieveConversationMessages(
        conversationId: conversationId,
        recentMessages: recentMessages,
        query: input ?? _latestRetrievalSeed(recentMessages),
      );
      _appendConversationContext(
        promptMessages,
        recentMessages: recentMessages,
        retrievedMessages: retrievedMessages,
      );
    }

    final inputText = input?.trim();
    promptMessages.add(
      AiPromptMessage(
        role: _aiRoleUser,
        content: [
          instruction.trim(),
          if (inputText != null && inputText.isNotEmpty) '\nText:\n$inputText',
        ].join('\n'),
      ),
    );
    d(
      'AI assist prompt built: conversationId=$conversationId '
      'messages=${promptMessages.length}',
    );
    return promptMessages;
  }

  List<AiPromptMessage> buildConversationSummaryPromptMessages({
    required AiConversationToolStats stats,
    required String? languageTag,
  }) {
    final outputLanguage = languageTag?.trim();
    return [
      AiPromptMessage(
        role: 'system',
        content:
            'You are a conversation summarizer inside a chat application. '
            'For this task, you must use the available read-only '
            'conversation tools to inspect the requested time range '
            'before writing the final answer. Start by calling '
            'list_conversation_chunks for the exact range, then '
            'read_conversation_chunk until you have covered the full '
            'range. Do not rely only on recent context or search for '
            'this task.',
      ),
      AiPromptMessage(
        role: 'system',
        content:
            'Summaries must cover the requested range completely and '
            'should include main topics, key decisions, action items, '
            'unresolved questions, and notable follow-ups. Keep the '
            'final answer concise but comprehensive.',
      ),
      AiPromptMessage(
        role: 'user',
        content: [
          'Summarize the conversation messages in this time range.',
          'Conversation ID: ${stats.conversationId}',
          'Start time: ${stats.startInclusive?.toIso8601String() ?? 'unspecified'}',
          'End time: ${stats.endExclusive?.toIso8601String() ?? 'unspecified'}',
          'Messages in range: ${stats.messageCount}',
          if (stats.firstMessageAt != null)
            'First message at: ${stats.firstMessageAt!.toIso8601String()}',
          if (stats.lastMessageAt != null)
            'Last message at: ${stats.lastMessageAt!.toIso8601String()}',
          if (outputLanguage != null && outputLanguage.isNotEmpty)
            'Write the final summary in $outputLanguage.',
          'Before finalizing, make sure you have covered every chunk in the range.',
          'Return only the summary text.',
        ].join('\n'),
      ),
    ];
  }

  void _appendConversationToolInstruction(
    List<AiPromptMessage> promptMessages, {
    required bool enabled,
  }) {
    if (!enabled) {
      return;
    }
    promptMessages.add(
      AiPromptMessage(
        role: 'system',
        content:
            'Read-only conversation tools are available for the current '
            'conversation. Use them when you need exhaustive coverage, '
            'date-scoped summaries, statistics, older messages, or more '
            'context than the provided messages. Do not call tools when '
            'the provided context is already sufficient.',
      ),
    );
  }

  void _appendConversationContext(
    List<AiPromptMessage> promptMessages, {
    required List<MessageItem> recentMessages,
    required List<SearchMessageDetailItem> retrievedMessages,
  }) {
    if (recentMessages.isNotEmpty) {
      final lines = recentMessages.reversed
          .map(
            (message) => _conversationContextLine(
              createdAt: message.createdAt,
              sender: message.userFullName ?? message.userId,
              content: _messagePlainText(message),
            ),
          )
          .join('\n');
      promptMessages.add(
        AiPromptMessage(
          role: 'system',
          content: 'Current conversation recent messages:\n$lines',
        ),
      );
    }

    if (retrievedMessages.isEmpty) {
      return;
    }

    final lines = retrievedMessages
        .map(
          (message) => _conversationContextLine(
            createdAt: message.createdAt,
            sender: message.senderFullName ?? message.senderId,
            content: _searchMessagePlainText(message),
          ),
        )
        .join('\n');
    promptMessages.add(
      AiPromptMessage(
        role: 'system',
        content:
            'Relevant older conversation messages matched by search '
            '(use only if they help answer the current request):\n$lines',
      ),
    );
  }

  Future<List<SearchMessageDetailItem>> _retrieveConversationMessages({
    required String conversationId,
    required List<MessageItem> recentMessages,
    required String? query,
  }) async {
    final normalizedQuery = _normalizeRetrievalQuery(query);
    if (normalizedQuery == null) {
      d('AI retrieval skipped: conversationId=$conversationId empty query');
      return const [];
    }

    final recentIds = recentMessages
        .map((message) => message.messageId)
        .toSet();
    final matchedIds = await database.ftsDatabase.fuzzySearchMessage(
      query: normalizedQuery,
      limit: _aiRetrievedMessageLimit + recentIds.length,
      conversationIds: [conversationId],
    );
    final candidateIds = matchedIds
        .where((messageId) => !recentIds.contains(messageId))
        .take(_aiRetrievedMessageLimit)
        .toList(growable: false);
    if (candidateIds.isEmpty) {
      d(
        'AI retrieval no match: conversationId=$conversationId '
        'query=${_previewText(normalizedQuery)}',
      );
      return const [];
    }

    final matchedMessages = await database.messageDao
        .searchMessageByIds(candidateIds)
        .get();
    final messagesById = {
      for (final message in matchedMessages) message.messageId: message,
    };
    final ordered = <SearchMessageDetailItem>[];
    for (final messageId in candidateIds) {
      final message = messagesById[messageId];
      if (message != null) {
        ordered.add(message);
      }
    }
    ordered.sort((left, right) => left.createdAt.compareTo(right.createdAt));
    d(
      'AI retrieval matched: conversationId=$conversationId '
      'query=${_previewText(normalizedQuery)} matches=${ordered.length}',
    );
    return ordered;
  }

  String? _latestRetrievalSeed(List<MessageItem> recentMessages) {
    for (final message in recentMessages) {
      final content = _messagePlainText(message);
      final normalized = _normalizeRetrievalQuery(content);
      if (normalized != null) {
        return normalized;
      }
    }
    return null;
  }

  String? _normalizeRetrievalQuery(String? query) {
    final compact = query?.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact == null || compact.isEmpty) {
      return null;
    }
    if (compact.length <= _aiRetrievalQueryMaxLength) {
      return compact;
    }
    return compact.substring(0, _aiRetrievalQueryMaxLength);
  }

  String _conversationContextLine({
    required DateTime createdAt,
    required String sender,
    required String content,
  }) => '[${createdAt.toIso8601String()}] $sender: $content';

  String _messagePlainText(MessageItem message) => _messagePlainTextFromFields(
    content: message.content,
    mediaName: message.mediaName,
    type: message.type,
  );

  String _searchMessagePlainText(SearchMessageDetailItem message) =>
      _messagePlainTextFromFields(
        content: message.content,
        mediaName: message.mediaName,
        type: message.type,
      );

  String _messagePlainTextFromFields({
    required String? content,
    required String? mediaName,
    required String type,
  }) {
    if (content?.trim().isNotEmpty == true) {
      return content!.trim();
    }
    if (mediaName?.isNotEmpty == true) {
      return '[$type] $mediaName';
    }
    return '[$type]';
  }
}

String _previewText(
  String? text, {
  int maxLength = AiChatPromptBuilder._aiLogPreviewLength,
}) {
  final compact = text?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
  if (compact.isEmpty) {
    return '""';
  }
  if (compact.length <= maxLength) {
    return compact;
  }
  return '${compact.substring(0, maxLength)}...(${compact.length} chars)';
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
