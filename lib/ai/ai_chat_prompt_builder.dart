import 'dart:async';

import 'package:mixin_logger/mixin_logger.dart';

import '../db/dao/message_dao.dart';
import '../db/database.dart';
import '../db/mixin_database.dart';
import 'model/ai_prompt_message.dart';
import 'model/ai_prompt_template.dart';

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
    String language,
  ) async {
    final now = DateTime.now();
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
      ..._promptMessages(
        role: 'system',
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
      retrievedMessages: retrievedMessages,
      language: language,
      now: now,
    );

    final history = aiMessages
        .where((element) => element.status != _aiStatusPending)
        .takeLast(_aiHistoryLimit);
    for (final item in history) {
      promptMessages.add(
        AiPromptMessage(role: item.role, content: item.content),
      );
    }

    promptMessages.addAll(
      _promptMessages(
        role: _aiRoleUser,
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
      'recent=${recentMessages.length} retrieved=${retrievedMessages.length} '
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
        role: 'system',
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
      final retrievedMessages = await _retrieveConversationMessages(
        conversationId: conversationId,
        recentMessages: recentMessages,
        query: input ?? _latestRetrievalSeed(recentMessages),
      );
      _appendConversationContext(
        promptMessages,
        conversationId: conversationId,
        recentMessages: recentMessages,
        retrievedMessages: retrievedMessages,
        language: language,
        now: now,
      );
    }

    promptMessages.addAll(
      _promptMessages(
        role: _aiRoleUser,
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
        role: 'system',
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
    required List<SearchMessageDetailItem> retrievedMessages,
    required String language,
    required DateTime now,
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
      promptMessages.addAll(
        _promptMessages(
          role: 'system',
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
    promptMessages.addAll(
      _promptMessages(
        role: 'system',
        content: renderAiPromptTemplate(
          retrievedConversationContextPromptTemplate,
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

  List<AiPromptMessage> _promptMessages({
    required String role,
    required String content,
  }) {
    if (content.trim().isEmpty) {
      return const [];
    }
    return [AiPromptMessage(role: role, content: content)];
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
