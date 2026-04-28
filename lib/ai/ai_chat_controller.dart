import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:uuid/uuid.dart';

import '../db/dao/ai_chat_message_dao.dart';
import '../db/dao/message_dao.dart';
import '../db/database.dart';
import '../db/mixin_database.dart';
import '../utils/proxy.dart';
import 'model/ai_prompt_message.dart';
import 'model/ai_provider_config.dart';
import 'model/ai_provider_type.dart';
import 'model/ai_tool.dart';
import 'tools/ai_conversation_tool_service.dart';

const _kAiRoleUser = 'user';
const _kAiRoleAssistant = 'assistant';
const _kAiStatusPending = 'pending';
const _kAiStatusDone = 'done';
const _kAiStatusError = 'error';
const _kAiContextMessageLimit = 30;
const _kAiRetrievedMessageLimit = 6;
const _kAiHistoryLimit = 12;
const _kAiStreamFlushChars = 32;
const _kAiStreamFlushInterval = Duration(milliseconds: 80);
const _kAiRetrievalQueryMaxLength = 120;
const _kAiToolMaxRounds = 8;
const _kAiLogPreviewLength = 240;
const _kAiLogJsonPreviewLength = 480;
final kAiRuntimeStartedAt = DateTime.now();
final _activeAiRequests = <String, CancelToken>{};

bool isActivePendingAiMessage(AiChatMessage message) =>
    message.role == _kAiRoleAssistant &&
    message.status == _kAiStatusPending &&
    !message.updatedAt.isBefore(kAiRuntimeStartedAt);

class AiChatController {
  AiChatController(this.database);

  final Database database;
  final _uuid = const Uuid();
  static const _openAiStrategy = _OpenAiCompatibleStrategy();
  static const _anthropicStrategy = _AnthropicStrategy();
  static const _geminiStrategy = _GeminiStrategy();
  late final DatabaseAiConversationToolService _conversationToolService =
      DatabaseAiConversationToolService(database);
  late final AiConversationToolKit _conversationTools = AiConversationToolKit(
    _conversationToolService,
  );

  Future<String> assistText({
    required String instruction,
    String? input,
    String? conversationId,
    AiProviderConfig? provider,
  }) async {
    final config = provider ?? database.settingProperties.selectedAiProvider;
    if (config == null) {
      throw Exception('No AI provider configured');
    }

    d(
      'AI assist start: provider=${config.type.name} model=${config.model} '
      'conversationId=$conversationId instruction=${_previewText(instruction)} '
      'input=${_previewText(input)}',
    );

    final messages = await _buildAssistPromptMessages(
      instruction: instruction,
      input: input,
      conversationId: conversationId,
    );

    final cancelToken = CancelToken();
    if (conversationId != null) {
      _activeAiRequests[conversationId] = cancelToken;
    }
    try {
      final result = await _requestText(
        config,
        messages,
        cancelToken: cancelToken,
        onContent: (_) async {},
        conversationId: conversationId,
        streamFinalResponse: false,
      );
      d(
        'AI assist done: provider=${config.type.name} model=${config.model} '
        'conversationId=$conversationId output=${_previewText(result)}',
      );
      return result;
    } finally {
      if (conversationId != null &&
          _activeAiRequests[conversationId] == cancelToken) {
        _activeAiRequests.remove(conversationId);
      }
    }
  }

  Future<void> send({
    required String conversationId,
    required String input,
    AiProviderConfig? provider,
    void Function()? onInputAccepted,
  }) async {
    await database.aiChatMessageDao.resolveStalePendingAssistantMessages(
      updatedBefore: kAiRuntimeStartedAt,
      conversationId: conversationId,
    );
    final hasPendingAssistant = await database.aiChatMessageDao
        .hasPendingAssistantMessage(
          conversationId,
          updatedAfter: kAiRuntimeStartedAt,
        );
    if (hasPendingAssistant) {
      throw Exception('AI is still responding');
    }

    final config = provider ?? database.settingProperties.selectedAiProvider;
    if (config == null) {
      throw Exception('No AI provider configured');
    }

    d(
      'AI send start: conversationId=$conversationId '
      'provider=${config.type.name} model=${config.model} '
      'input=${_previewText(input)}',
    );

    final now = DateTime.now();
    final userMessageId = _uuid.v4();
    final assistantMessageId = _uuid.v4();
    final cancelToken = CancelToken();
    final anchorMessage = await database.messageDao
        .messagesByConversationId(conversationId, 1)
        .getSingleOrNull();

    await database.aiChatMessageDao.insertMessage(
      AiChatMessagesCompanion.insert(
        id: userMessageId,
        conversationId: conversationId,
        role: _kAiRoleUser,
        providerId: config.id,
        anchorMessageId: Value(anchorMessage?.messageId),
        anchorCreatedAt: Value(anchorMessage?.createdAt),
        content: input,
        status: _kAiStatusDone,
        model: Value(config.model),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.aiChatMessageDao.insertMessage(
      AiChatMessagesCompanion.insert(
        id: assistantMessageId,
        conversationId: conversationId,
        role: _kAiRoleAssistant,
        providerId: config.id,
        anchorMessageId: Value(anchorMessage?.messageId),
        anchorCreatedAt: Value(anchorMessage?.createdAt),
        content: '',
        status: _kAiStatusPending,
        model: Value(config.model),
        createdAt: now,
        updatedAt: now,
      ),
    );

    onInputAccepted?.call();

    final updater = _StreamingMessageUpdater(
      dao: database.aiChatMessageDao,
      messageId: assistantMessageId,
    );
    _activeAiRequests[conversationId] = cancelToken;
    try {
      final messages = await _buildPromptMessages(conversationId, input);
      final result = await _requestText(
        config,
        messages,
        cancelToken: cancelToken,
        onContent: updater.append,
        conversationId: conversationId,
        streamFinalResponse: true,
      );
      await updater.flush(contentOverride: result, force: true);
      await database.aiChatMessageDao.updateMessageStatus(
        assistantMessageId,
        _kAiStatusDone,
        updatedAt: DateTime.now(),
      );
      d(
        'AI send done: conversationId=$conversationId '
        'assistantMessageId=$assistantMessageId output=${_previewText(result)}',
      );
    } catch (error, stacktrace) {
      if (cancelToken.isCancelled) {
        d(
          'AI send cancelled: conversationId=$conversationId '
          'assistantMessageId=$assistantMessageId',
        );
        await updater.flush(force: true);
        await database.aiChatMessageDao.updateMessageStatus(
          assistantMessageId,
          _kAiStatusDone,
          updatedAt: DateTime.now(),
          errorText: 'Stopped',
        );
        return;
      }
      e('AI chat error: $error, $stacktrace');
      await database.aiChatMessageDao.updateMessageStatus(
        assistantMessageId,
        _kAiStatusError,
        updatedAt: DateTime.now(),
        errorText: error.toString(),
      );
      rethrow;
    } finally {
      if (_activeAiRequests[conversationId] == cancelToken) {
        _activeAiRequests.remove(conversationId);
      }
    }
  }

  void stop(String conversationId) {
    d('AI stop requested: conversationId=$conversationId');
    _activeAiRequests[conversationId]?.cancel('AI generation stopped');
  }

  Future<String> summarizeConversationRange({
    required String conversationId,
    required DateTime startInclusive,
    required DateTime endExclusive,
    String? languageTag,
    AiProviderConfig? provider,
  }) async {
    final config = provider ?? database.settingProperties.selectedAiProvider;
    if (config == null) {
      throw Exception('No AI provider configured');
    }

    final stats = await _conversationToolService.getConversationStats(
      conversationId: conversationId,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
    if (stats.messageCount <= 0) {
      return 'No messages found in the selected time range.';
    }

    final messages = _buildConversationSummaryPromptMessages(
      stats: stats,
      languageTag: languageTag,
    );
    final cancelToken = CancelToken();
    _activeAiRequests[conversationId] = cancelToken;
    try {
      return await _requestText(
        config,
        messages,
        cancelToken: cancelToken,
        onContent: (_) async {},
        conversationId: conversationId,
        streamFinalResponse: false,
      );
    } finally {
      if (_activeAiRequests[conversationId] == cancelToken) {
        _activeAiRequests.remove(conversationId);
      }
    }
  }

  Future<String> summarizeConversationToday({
    required String conversationId,
    String? languageTag,
    AiProviderConfig? provider,
    DateTime? now,
  }) {
    final localNow = now ?? DateTime.now();
    final startInclusive = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
    );
    return summarizeConversationRange(
      conversationId: conversationId,
      startInclusive: startInclusive,
      endExclusive: startInclusive.add(const Duration(days: 1)),
      languageTag: languageTag,
      provider: provider,
    );
  }

  Future<List<AiPromptMessage>> _buildPromptMessages(
    String conversationId,
    String input,
  ) async {
    final recentMessages = await database.messageDao
        .messagesByConversationId(conversationId, _kAiContextMessageLimit)
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
            'Help summarize, answer questions about the conversation, and draft replies. '
            'Be concise and practical.',
      ),
    ];

    _appendConversationToolInstruction(promptMessages, enabled: true);
    _appendConversationContext(
      promptMessages,
      recentMessages: recentMessages,
      retrievedMessages: retrievedMessages,
    );

    final history = aiMessages
        .where((element) => element.status != _kAiStatusPending)
        .takeLast(_kAiHistoryLimit);
    for (final item in history) {
      promptMessages.add(
        AiPromptMessage(role: item.role, content: item.content),
      );
    }

    promptMessages.add(AiPromptMessage(role: _kAiRoleUser, content: input));
    d(
      'AI prompt built: conversationId=$conversationId '
      'recent=${recentMessages.length} retrieved=${retrievedMessages.length} '
      'history=${history.length} promptMessages=${promptMessages.length}',
    );
    return promptMessages;
  }

  Future<List<AiPromptMessage>> _buildAssistPromptMessages({
    required String instruction,
    required String? input,
    required String? conversationId,
  }) async {
    final promptMessages = <AiPromptMessage>[
      AiPromptMessage(
        role: 'system',
        content:
            'You are an invisible writing assistant inside a chat app. '
            'Return only the requested text. Do not add explanations, labels, '
            'markdown fences, or greetings unless explicitly requested.',
      ),
    ];

    if (conversationId != null) {
      _appendConversationToolInstruction(promptMessages, enabled: true);
      final recentMessages = await database.messageDao
          .messagesByConversationId(conversationId, _kAiContextMessageLimit)
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
        role: _kAiRoleUser,
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

  List<AiPromptMessage> _buildConversationSummaryPromptMessages({
    required AiConversationToolStats stats,
    required String? languageTag,
  }) {
    final outputLanguage = languageTag?.trim();
    return [
      AiPromptMessage(
        role: 'system',
        content:
            'You are a conversation summarizer inside a chat application. '
            'For this task, you must use the available read-only conversation tools '
            'to inspect the requested time range before writing the final answer. '
            'Start by calling list_conversation_chunks for the exact range, then '
            'read_conversation_chunk until you have covered the full range. '
            'Do not rely only on recent context or search for this task.',
      ),
      AiPromptMessage(
        role: 'system',
        content:
            'Summaries must cover the requested range completely and should include '
            'main topics, key decisions, action items, unresolved questions, and '
            'notable follow-ups. Keep the final answer concise but comprehensive.',
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
            'Read-only conversation tools are available for the current conversation. '
            'Use them when you need exhaustive coverage, date-scoped summaries, '
            'statistics, older messages, or more context than the provided messages. '
            'Do not call tools when the provided context is already sufficient.',
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
      limit: _kAiRetrievedMessageLimit + recentIds.length,
      conversationIds: [conversationId],
    );
    final candidateIds = matchedIds
        .where((messageId) => !recentIds.contains(messageId))
        .take(_kAiRetrievedMessageLimit)
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
    if (compact.length <= _kAiRetrievalQueryMaxLength) {
      return compact;
    }
    return compact.substring(0, _kAiRetrievalQueryMaxLength);
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

  Future<String> _requestText(
    AiProviderConfig config,
    List<AiPromptMessage> messages, {
    required CancelToken cancelToken,
    required Future<void> Function(String chunk) onContent,
    required bool streamFinalResponse,
    String? conversationId,
  }) async {
    d(
      'AI request start: provider=${config.type.name} model=${config.model} '
      'conversationId=$conversationId streamFinal=$streamFinalResponse '
      'messages=${messages.length} tools=${conversationId != null}',
    );
    final dio =
        Dio(
            BaseOptions(
              baseUrl: config.baseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(minutes: 5),
              sendTimeout: const Duration(seconds: 20),
              headers: _strategyFor(config.type).headers(config),
            ),
          )
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                options.extra['ai_request_started_at'] = DateTime.now();
                d(
                  'AI HTTP request: ${options.method} ${options.uri} '
                  'provider=${config.type.name} model=${config.model}',
                );
                handler.next(options);
              },
              onResponse: (response, handler) {
                final startedAt =
                    response.requestOptions.extra['ai_request_started_at']
                        as DateTime?;
                d(
                  'AI HTTP response: ${response.requestOptions.method} '
                  '${response.requestOptions.uri} status=${response.statusCode} '
                  'elapsedMs=${startedAt == null ? -1 : DateTime.now().difference(startedAt).inMilliseconds}',
                );
                handler.next(response);
              },
              onError: (error, handler) {
                final startedAt =
                    error.requestOptions.extra['ai_request_started_at']
                        as DateTime?;
                e(
                  'AI HTTP error: ${error.requestOptions.method} '
                  '${error.requestOptions.uri} '
                  'elapsedMs=${startedAt == null ? -1 : DateTime.now().difference(startedAt).inMilliseconds} '
                  'error=${error.message}',
                  error,
                  error.stackTrace,
                );
                handler.next(error);
              },
            ),
          )
          ..applyProxy(database.settingProperties.activatedProxy);

    if (conversationId == null) {
      return _strategyFor(config.type).streamResponse(
        dio: dio,
        config: config,
        messages: messages,
        cancelToken: cancelToken,
        onContent: onContent,
      );
    }

    return _requestWithTools(
      dio,
      config,
      [...messages],
      conversationId: conversationId,
      cancelToken: cancelToken,
      onContent: onContent,
      streamFinalResponse: streamFinalResponse,
    );
  }

  Future<String> _requestWithTools(
    Dio dio,
    AiProviderConfig config,
    List<AiPromptMessage> messages, {
    required String conversationId,
    required CancelToken cancelToken,
    required Future<void> Function(String chunk) onContent,
    required bool streamFinalResponse,
  }) async {
    for (var round = 0; round < _kAiToolMaxRounds; round++) {
      d(
        'AI tool round start: conversationId=$conversationId '
        'round=${round + 1}/$_kAiToolMaxRounds messages=${messages.length}',
      );
      final response = await _strategyFor(config.type).completeResponse(
        dio: dio,
        config: config,
        messages: messages,
        tools: AiConversationToolKit.definitions,
        cancelToken: cancelToken,
      );
      d(
        'AI tool round response: conversationId=$conversationId '
        'round=${round + 1} text=${_previewText(response.text)} '
        'toolCalls=${_previewToolCalls(response.toolCalls)}',
      );

      if (!response.hasToolCalls) {
        final text = response.text.trim();
        if (text.isEmpty) {
          throw Exception('Empty AI response');
        }
        if (streamFinalResponse) {
          try {
            d(
              'AI final stream start: conversationId=$conversationId '
              'round=${round + 1}',
            );
            return await _strategyFor(config.type).streamResponse(
              dio: dio,
              config: config,
              messages: messages,
              cancelToken: cancelToken,
              onContent: onContent,
            );
          } catch (error, stacktrace) {
            e('AI final streaming fallback: $error, $stacktrace');
            await _emitBufferedText(text, onContent);
            d(
              'AI final stream fallback: conversationId=$conversationId '
              'round=${round + 1} text=${_previewText(text)}',
            );
            return text;
          }
        }
        await onContent(text);
        d(
          'AI tool request done without stream: conversationId=$conversationId '
          'round=${round + 1} text=${_previewText(text)}',
        );
        return text;
      }

      messages.add(
        AiPromptMessage(
          role: _kAiRoleAssistant,
          content: response.text,
          toolCalls: response.toolCalls,
        ),
      );
      for (final toolCall in response.toolCalls) {
        final result = await _executeConversationTool(
          conversationId: conversationId,
          toolCall: toolCall,
        );
        messages.add(
          AiPromptMessage(
            role: 'tool',
            content: result.content,
            toolCallId: result.toolCallId,
            toolName: result.toolName,
            toolPayload: result.payload,
          ),
        );
      }
    }

    e(
      'AI exceeded tool call limit: conversationId=$conversationId '
      'maxRounds=$_kAiToolMaxRounds',
    );
    throw Exception('AI exceeded tool call limit');
  }

  Future<void> _emitBufferedText(
    String text,
    Future<void> Function(String chunk) onContent,
  ) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    if (trimmed.length <= _kAiStreamFlushChars) {
      await onContent(trimmed);
      return;
    }
    for (var start = 0; start < trimmed.length; start += _kAiStreamFlushChars) {
      final end = (start + _kAiStreamFlushChars).clamp(0, trimmed.length);
      await onContent(trimmed.substring(start, end));
    }
  }

  Future<AiToolExecutionResult> _executeConversationTool({
    required String conversationId,
    required AiToolCall toolCall,
  }) async {
    final stopwatch = Stopwatch()..start();
    d(
      'AI tool execute start: conversationId=$conversationId '
      'tool=${toolCall.name} id=${toolCall.id} '
      'arguments=${_previewJson(toolCall.arguments)}',
    );
    try {
      final result = await _conversationTools.execute(
        conversationId: conversationId,
        call: toolCall,
      );
      d(
        'AI tool execute done: conversationId=$conversationId '
        'tool=${toolCall.name} id=${toolCall.id} '
        'elapsedMs=${stopwatch.elapsedMilliseconds} '
        'result=${_previewJson(result.payload)}',
      );
      return result;
    } catch (error, stacktrace) {
      e('AI tool execution error: $error, $stacktrace');
      return AiToolExecutionResult(
        toolCallId: toolCall.id,
        toolName: toolCall.name,
        payload: {'error': '$error'},
      );
    }
  }

  _AiProviderStrategy _strategyFor(AiProviderType type) => switch (type) {
    AiProviderType.openaiCompatible => _openAiStrategy,
    AiProviderType.anthropic => _anthropicStrategy,
    AiProviderType.gemini => _geminiStrategy,
  };
}

String _previewText(String? text, {int maxLength = _kAiLogPreviewLength}) {
  final compact = text?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
  if (compact.isEmpty) {
    return '""';
  }
  if (compact.length <= maxLength) {
    return compact;
  }
  return '${compact.substring(0, maxLength)}...(${compact.length} chars)';
}

String _previewJson(Object? value, {int maxLength = _kAiLogJsonPreviewLength}) {
  try {
    final encoded = jsonEncode(value);
    if (encoded.length <= maxLength) {
      return encoded;
    }
    return '${encoded.substring(0, maxLength)}...(${encoded.length} chars)';
  } catch (_) {
    return '$value';
  }
}

String _previewToolCalls(List<AiToolCall> toolCalls) {
  if (toolCalls.isEmpty) {
    return '[]';
  }
  return toolCalls
      .map(
        (toolCall) =>
            '${toolCall.name}#${toolCall.id}(${_previewJson(toolCall.arguments, maxLength: 120)})',
      )
      .join(', ');
}

extension<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    if (count <= 0) return const [];
    final list = toList();
    if (list.length <= count) {
      return list;
    }
    return list.sublist(list.length - count);
  }
}

abstract interface class _AiProviderStrategy {
  const _AiProviderStrategy();

  Map<String, dynamic> headers(AiProviderConfig config);

  Future<_AiCompletionResponse> completeResponse({
    required Dio dio,
    required AiProviderConfig config,
    required List<AiPromptMessage> messages,
    required List<AiToolDefinition> tools,
    required CancelToken cancelToken,
  });

  Future<String> streamResponse({
    required Dio dio,
    required AiProviderConfig config,
    required List<AiPromptMessage> messages,
    required CancelToken cancelToken,
    required Future<void> Function(String chunk) onContent,
  });
}

class _OpenAiCompatibleStrategy implements _AiProviderStrategy {
  const _OpenAiCompatibleStrategy();

  @override
  Map<String, dynamic> headers(AiProviderConfig config) => {
    'Authorization': 'Bearer ${config.apiKey}',
    'Content-Type': 'application/json',
  };

  @override
  Future<_AiCompletionResponse> completeResponse({
    required Dio dio,
    required AiProviderConfig config,
    required List<AiPromptMessage> messages,
    required List<AiToolDefinition> tools,
    required CancelToken cancelToken,
  }) async {
    final response = await dio.post<dynamic>(
      '/chat/completions',
      data: {
        'model': config.model,
        'messages': messages.map(_openAiMessagePayload).toList(growable: false),
        if (tools.isNotEmpty)
          'tools': tools
              .map(
                (tool) => {
                  'type': 'function',
                  'function': {
                    'name': tool.name,
                    'description': tool.description,
                    'parameters': tool.inputSchema,
                  },
                },
              )
              .toList(growable: false),
        if (tools.isNotEmpty) 'tool_choice': 'auto',
      },
      cancelToken: cancelToken,
    );

    final body = _jsonMap(response.data);
    final choices = body['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Empty AI response');
    }
    final first = _jsonMap(choices.first);
    final message = _jsonMap(first['message']);
    final text = _stringContent(message['content']);
    final toolCalls = (message['tool_calls'] as List<dynamic>? ?? const [])
        .map((item) => _openAiToolCall(_jsonMap(item)))
        .toList(growable: false);
    if (text.trim().isEmpty && toolCalls.isEmpty) {
      throw Exception('Empty AI response');
    }
    return _AiCompletionResponse(text: text, toolCalls: toolCalls);
  }

  @override
  Future<String> streamResponse({
    required Dio dio,
    required AiProviderConfig config,
    required List<AiPromptMessage> messages,
    required CancelToken cancelToken,
    required Future<void> Function(String chunk) onContent,
  }) async {
    final response = await dio.post<ResponseBody>(
      '/chat/completions',
      data: {
        'model': config.model,
        'stream': true,
        'messages': messages.map(_openAiMessagePayload).toList(growable: false),
      },
      options: Options(responseType: ResponseType.stream),
      cancelToken: cancelToken,
    );

    final body = response.data;
    if (body == null) {
      throw Exception('Empty AI response');
    }

    final buffer = StringBuffer();
    await for (final data in _decodeSse(body.stream)) {
      if (data == '[DONE]') {
        continue;
      }

      final json = jsonDecode(data);
      if (json is! Map<String, dynamic>) {
        continue;
      }

      final choices = json['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        continue;
      }

      final first = choices.first;
      if (first is! Map<String, dynamic>) {
        continue;
      }

      final delta = first['delta'];
      if (delta is! Map<String, dynamic>) {
        continue;
      }

      final content = delta['content'];
      if (content is String && content.isNotEmpty) {
        buffer.write(content);
        await onContent(content);
      }
    }

    final text = buffer.toString().trim();
    if (text.isEmpty) {
      throw Exception('Empty AI response');
    }
    return text;
  }

  Map<String, dynamic> _openAiMessagePayload(AiPromptMessage message) => {
    'role': message.role,
    'content': message.content,
    if (message.hasToolCalls)
      'tool_calls': message.toolCalls
          .map(
            (toolCall) => {
              'id': toolCall.id,
              'type': 'function',
              'function': {
                'name': toolCall.name,
                'arguments': jsonEncode(toolCall.arguments),
              },
            },
          )
          .toList(growable: false),
    if (message.isToolResult) 'tool_call_id': message.toolCallId,
  };

  AiToolCall _openAiToolCall(Map<String, dynamic> value) {
    final function = _jsonMap(value['function']);
    final name = function['name'] as String?;
    if (name == null || name.isEmpty) {
      throw Exception('Invalid AI tool call name');
    }
    return AiToolCall(
      id: value['id'] as String? ?? '${name}_${value.hashCode}',
      name: name,
      arguments: _toolArguments(function['arguments']),
    );
  }
}

class _AnthropicStrategy implements _AiProviderStrategy {
  const _AnthropicStrategy();

  @override
  Map<String, dynamic> headers(AiProviderConfig config) => {
    'x-api-key': config.apiKey,
    'anthropic-version': '2023-06-01',
    'content-type': 'application/json',
  };

  @override
  Future<_AiCompletionResponse> completeResponse({
    required Dio dio,
    required AiProviderConfig config,
    required List<AiPromptMessage> messages,
    required List<AiToolDefinition> tools,
    required CancelToken cancelToken,
  }) async {
    final response = await dio.post<dynamic>(
      '/messages',
      data: {
        'model': config.model,
        'max_tokens': 1024,
        'messages': messages
            .where((message) => message.role != 'system')
            .map(_anthropicMessagePayload)
            .toList(growable: false),
        'system': messages
            .where((message) => message.role == 'system')
            .map((message) => message.content)
            .where((content) => content.isNotEmpty)
            .join('\n\n'),
        if (tools.isNotEmpty)
          'tools': tools
              .map(
                (tool) => {
                  'name': tool.name,
                  'description': tool.description,
                  'input_schema': tool.inputSchema,
                },
              )
              .toList(growable: false),
      },
      cancelToken: cancelToken,
    );

    final body = _jsonMap(response.data);
    if (body['type'] == 'error') {
      final error = _jsonMap(body['error']);
      throw Exception(error['message'] ?? 'Anthropic request failed');
    }

    final content = body['content'] as List<dynamic>?;
    if (content == null || content.isEmpty) {
      throw Exception('Empty AI response');
    }

    final textBuffer = StringBuffer();
    final toolCalls = <AiToolCall>[];
    for (final item in content) {
      final block = _jsonMap(item);
      switch (block['type']) {
        case 'text':
          final text = block['text'];
          if (text is String && text.isNotEmpty) {
            textBuffer.write(text);
          }
        case 'tool_use':
          final name = block['name'] as String?;
          if (name == null || name.isEmpty) {
            throw Exception('Invalid AI tool call name');
          }
          toolCalls.add(
            AiToolCall(
              id: block['id'] as String? ?? '${name}_${block.hashCode}',
              name: name,
              arguments: _toolArguments(block['input']),
            ),
          );
      }
    }

    final text = textBuffer.toString();
    if (text.trim().isEmpty && toolCalls.isEmpty) {
      throw Exception('Empty AI response');
    }
    return _AiCompletionResponse(text: text, toolCalls: toolCalls);
  }

  @override
  Future<String> streamResponse({
    required Dio dio,
    required AiProviderConfig config,
    required List<AiPromptMessage> messages,
    required CancelToken cancelToken,
    required Future<void> Function(String chunk) onContent,
  }) async {
    final response = await dio.post<ResponseBody>(
      '/messages',
      data: {
        'model': config.model,
        'max_tokens': 1024,
        'stream': true,
        'messages': messages
            .where((message) => message.role != 'system')
            .map(_anthropicMessagePayload)
            .toList(growable: false),
        'system': messages
            .where((message) => message.role == 'system')
            .map((message) => message.content)
            .join('\n\n'),
      },
      options: Options(responseType: ResponseType.stream),
      cancelToken: cancelToken,
    );

    final body = response.data;
    if (body == null) {
      throw Exception('Empty AI response');
    }

    final buffer = StringBuffer();
    await for (final data in _decodeSse(body.stream)) {
      final json = jsonDecode(data);
      if (json is! Map<String, dynamic>) {
        continue;
      }

      final type = json['type'] as String?;
      if (type == 'error') {
        final error = json['error'];
        if (error is Map<String, dynamic>) {
          throw Exception(error['message'] ?? 'Anthropic request failed');
        }
        throw Exception('Anthropic request failed');
      }

      if (type != 'content_block_delta') {
        continue;
      }

      final delta = json['delta'];
      if (delta is! Map<String, dynamic>) {
        continue;
      }

      if (delta['type'] != 'text_delta') {
        continue;
      }

      final text = delta['text'];
      if (text is String && text.isNotEmpty) {
        buffer.write(text);
        await onContent(text);
      }
    }

    final text = buffer.toString().trim();
    if (text.isEmpty) {
      throw Exception('Empty AI response');
    }
    return text;
  }

  Map<String, dynamic> _anthropicMessagePayload(AiPromptMessage message) => {
    'role': message.isToolResult ? 'user' : message.role,
    'content': _anthropicContentBlocks(message),
  };

  List<Map<String, dynamic>> _anthropicContentBlocks(AiPromptMessage message) {
    if (message.isToolResult) {
      return [
        {
          'type': 'tool_result',
          'tool_use_id': message.toolCallId,
          'content': message.content,
        },
      ];
    }

    final blocks = <Map<String, dynamic>>[];
    if (message.content.isNotEmpty) {
      blocks.add({'type': 'text', 'text': message.content});
    }
    for (final toolCall in message.toolCalls) {
      blocks.add({
        'type': 'tool_use',
        'id': toolCall.id,
        'name': toolCall.name,
        'input': toolCall.arguments,
      });
    }
    return blocks;
  }
}

class _GeminiStrategy implements _AiProviderStrategy {
  const _GeminiStrategy();

  @override
  Map<String, dynamic> headers(AiProviderConfig config) => {
    'x-goog-api-key': config.apiKey,
    'content-type': 'application/json',
  };

  @override
  Future<_AiCompletionResponse> completeResponse({
    required Dio dio,
    required AiProviderConfig config,
    required List<AiPromptMessage> messages,
    required List<AiToolDefinition> tools,
    required CancelToken cancelToken,
  }) async {
    final systemInstruction = messages
        .where((message) => message.role == 'system')
        .map((message) => message.content.trim())
        .where((content) => content.isNotEmpty)
        .join('\n\n');
    final response = await dio.post<dynamic>(
      '/models/${Uri.encodeComponent(config.model)}:generateContent',
      data: {
        'contents': messages
            .where((message) => message.role != 'system')
            .map(_geminiMessagePayload)
            .toList(growable: false),
        if (systemInstruction.isNotEmpty)
          'system_instruction': {
            'parts': [
              {'text': systemInstruction},
            ],
          },
        if (tools.isNotEmpty)
          'tools': [
            {
              'functionDeclarations': tools
                  .map(
                    (tool) => {
                      'name': tool.name,
                      'description': tool.description,
                      'parameters': tool.inputSchema,
                    },
                  )
                  .toList(growable: false),
            },
          ],
        if (tools.isNotEmpty)
          'toolConfig': {
            'functionCallingConfig': {'mode': 'AUTO'},
          },
        'generationConfig': {
          'candidateCount': 1,
        },
      },
      cancelToken: cancelToken,
    );

    final body = _jsonMap(response.data);
    final promptFeedback = body['promptFeedback'];
    if (promptFeedback is Map<String, dynamic>) {
      final blockReason = promptFeedback['blockReason'];
      if (blockReason is String && blockReason.isNotEmpty) {
        throw Exception('Gemini request blocked: $blockReason');
      }
    }

    final candidates = body['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Empty AI response');
    }
    final first = _jsonMap(candidates.first);
    final finishReason = first['finishReason'];
    if (finishReason is String &&
        finishReason.isNotEmpty &&
        finishReason != 'STOP' &&
        finishReason != 'FINISH_REASON_UNSPECIFIED') {
      throw Exception('Gemini request finished with reason: $finishReason');
    }

    final content = _jsonMap(first['content']);
    final parts = content['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Empty AI response');
    }

    final textBuffer = StringBuffer();
    final toolCalls = <AiToolCall>[];
    for (final item in parts) {
      final part = _jsonMap(item);
      final text = part['text'];
      if (text is String && text.isNotEmpty) {
        textBuffer.write(text);
      }
      final functionCall = part['functionCall'];
      if (functionCall is Map<String, dynamic>) {
        final name = functionCall['name'] as String?;
        if (name == null || name.isEmpty) {
          throw Exception('Invalid AI tool call name');
        }
        toolCalls.add(
          AiToolCall(
            id: '${name}_${functionCall.hashCode}',
            name: name,
            arguments: _toolArguments(functionCall['args']),
          ),
        );
      }
    }

    final text = textBuffer.toString();
    if (text.trim().isEmpty && toolCalls.isEmpty) {
      throw Exception('Empty AI response');
    }
    return _AiCompletionResponse(text: text, toolCalls: toolCalls);
  }

  @override
  Future<String> streamResponse({
    required Dio dio,
    required AiProviderConfig config,
    required List<AiPromptMessage> messages,
    required CancelToken cancelToken,
    required Future<void> Function(String chunk) onContent,
  }) async {
    final systemInstruction = messages
        .where((message) => message.role == 'system')
        .map((message) => message.content.trim())
        .where((content) => content.isNotEmpty)
        .join('\n\n');

    final contents = messages
        .where((message) => message.role != 'system')
        .map(_geminiMessagePayload)
        .toList(growable: false);

    final response = await dio.post<ResponseBody>(
      '/models/${Uri.encodeComponent(config.model)}:streamGenerateContent',
      queryParameters: const {'alt': 'sse'},
      data: {
        'contents': contents,
        if (systemInstruction.isNotEmpty)
          'system_instruction': {
            'parts': [
              {'text': systemInstruction},
            ],
          },
        'generationConfig': {
          'candidateCount': 1,
        },
      },
      options: Options(responseType: ResponseType.stream),
      cancelToken: cancelToken,
    );

    final body = response.data;
    if (body == null) {
      throw Exception('Empty AI response');
    }

    final buffer = StringBuffer();
    await for (final data in _decodeSse(body.stream)) {
      final json = jsonDecode(data);
      if (json is! Map<String, dynamic>) {
        continue;
      }

      final promptFeedback = json['promptFeedback'];
      if (promptFeedback is Map<String, dynamic>) {
        final blockReason = promptFeedback['blockReason'];
        if (blockReason is String && blockReason.isNotEmpty) {
          throw Exception('Gemini request blocked: $blockReason');
        }
      }

      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        continue;
      }

      final first = candidates.first;
      if (first is! Map<String, dynamic>) {
        continue;
      }

      final finishReason = first['finishReason'];
      if (finishReason is String &&
          finishReason.isNotEmpty &&
          finishReason != 'STOP' &&
          finishReason != 'FINISH_REASON_UNSPECIFIED') {
        throw Exception('Gemini request finished with reason: $finishReason');
      }

      final content = first['content'];
      if (content is! Map<String, dynamic>) {
        continue;
      }

      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        continue;
      }

      for (final part in parts) {
        if (part is! Map<String, dynamic>) {
          continue;
        }
        final text = part['text'];
        if (text is String && text.isNotEmpty) {
          buffer.write(text);
          await onContent(text);
        }
      }
    }

    final text = buffer.toString().trim();
    if (text.isEmpty) {
      throw Exception('Empty AI response');
    }
    return text;
  }

  Map<String, dynamic> _geminiMessagePayload(AiPromptMessage message) => {
    'role': message.role == _kAiRoleAssistant ? 'model' : 'user',
    'parts': _geminiMessageParts(message),
  };

  List<Map<String, dynamic>> _geminiMessageParts(AiPromptMessage message) {
    if (message.isToolResult) {
      return [
        {
          'functionResponse': {
            'name': message.toolName,
            'response': message.toolPayload ?? {'content': message.content},
          },
        },
      ];
    }

    final parts = <Map<String, dynamic>>[];
    if (message.content.isNotEmpty) {
      parts.add({'text': message.content});
    }
    for (final toolCall in message.toolCalls) {
      parts.add({
        'functionCall': {
          'name': toolCall.name,
          'args': toolCall.arguments,
        },
      });
    }
    return parts;
  }
}

class _AiCompletionResponse {
  const _AiCompletionResponse({
    this.text = '',
    this.toolCalls = const [],
  });

  final String text;
  final List<AiToolCall> toolCalls;

  bool get hasToolCalls => toolCalls.isNotEmpty;
}

Map<String, dynamic> _jsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry('$key', value));
  }
  throw Exception('Invalid AI response payload');
}

Map<String, dynamic> _toolArguments(dynamic value) {
  if (value == null) {
    return const {};
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return const {};
    }
    final decoded = jsonDecode(trimmed);
    return _jsonMap(decoded);
  }
  return _jsonMap(value);
}

String _stringContent(dynamic value) {
  if (value is String) {
    return value;
  }
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => item['text'])
        .whereType<String>()
        .join('\n');
  }
  return '';
}

class _StreamingMessageUpdater {
  _StreamingMessageUpdater({required this.dao, required this.messageId});

  final AiChatMessageDao dao;
  final String messageId;
  final _buffer = StringBuffer();

  String _persistedContent = '';
  DateTime _lastFlushedAt = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> append(String chunk) async {
    if (chunk.isEmpty) return;

    _buffer.write(chunk);
    final now = DateTime.now();
    final pendingChars = _buffer.length - _persistedContent.length;
    if (pendingChars < _kAiStreamFlushChars &&
        now.difference(_lastFlushedAt) < _kAiStreamFlushInterval) {
      return;
    }

    await flush();
  }

  Future<void> flush({String? contentOverride, bool force = false}) async {
    final content = contentOverride ?? _buffer.toString();
    if (!force && content == _persistedContent) {
      return;
    }

    _persistedContent = content;
    _lastFlushedAt = DateTime.now();
    await dao.updateMessageContent(
      messageId,
      content,
      updatedAt: _lastFlushedAt,
    );
  }
}

Stream<String> _decodeSse(Stream<List<int>> stream) async* {
  final buffer = StringBuffer();
  await for (final bytes in stream) {
    final chunk = utf8.decode(bytes);
    buffer.write(chunk.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));
    while (true) {
      final current = buffer.toString();
      final separatorIndex = current.indexOf('\n\n');
      if (separatorIndex < 0) {
        break;
      }

      final rawEvent = current.substring(0, separatorIndex);
      final remaining = current.substring(separatorIndex + 2);
      buffer
        ..clear()
        ..write(remaining);

      final payload = rawEvent
          .split('\n')
          .where((line) => line.startsWith('data:'))
          .map((line) => line.substring(5).trimLeft())
          .join('\n')
          .trim();
      if (payload.isNotEmpty) {
        yield payload;
      }
    }
  }
}
