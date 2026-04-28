import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:uuid/uuid.dart';

import '../db/dao/ai_chat_message_dao.dart';
import '../db/database.dart';
import '../db/mixin_database.dart';
import 'ai_chat_prompt_builder.dart';
import 'ai_provider_requester.dart';
import 'model/ai_prompt_message.dart';
import 'model/ai_provider_config.dart';
import 'model/ai_tool.dart';
import 'tools/ai_conversation_tool_service.dart';

const _kAiRoleUser = 'user';
const _kAiRoleAssistant = 'assistant';
const _kAiStatusPending = 'pending';
const _kAiStatusDone = 'done';
const _kAiStatusError = 'error';
const _kAiStreamFlushChars = 32;
const _kAiStreamFlushInterval = Duration(milliseconds: 80);
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
  static const _providerRequester = AiProviderRequester();
  late final DatabaseAiConversationToolService _conversationToolService =
      DatabaseAiConversationToolService(database);
  late final AiConversationToolKit _conversationTools = AiConversationToolKit(
    _conversationToolService,
  );
  late final AiChatPromptBuilder _promptBuilder = AiChatPromptBuilder(database);

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

    final messages = await _promptBuilder.buildAssistPromptMessages(
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
      final messages = await _promptBuilder.buildPromptMessages(
        conversationId,
        input,
      );
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

    final messages = _promptBuilder.buildConversationSummaryPromptMessages(
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

  Future<String> _requestText(
    AiProviderConfig config,
    List<AiPromptMessage> messages, {
    required CancelToken cancelToken,
    required Future<void> Function(String chunk) onContent,
    required bool streamFinalResponse,
    String? conversationId,
  }) => _providerRequester.requestText(
    config,
    messages,
    proxy: database.settingProperties.activatedProxy,
    cancelToken: cancelToken,
    onContent: onContent,
    streamFinalResponse: streamFinalResponse,
    conversationId: conversationId,
    onToolCall: _toolExecutorFor(conversationId),
  );

  Future<AiToolExecutionResult> Function(AiToolCall toolCall)? _toolExecutorFor(
    String? conversationId,
  ) {
    if (conversationId == null) {
      return null;
    }
    return (toolCall) => _executeConversationTool(
      conversationId: conversationId,
      toolCall: toolCall,
    );
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
