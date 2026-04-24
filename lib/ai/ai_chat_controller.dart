import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:uuid/uuid.dart';

import '../db/dao/ai_chat_message_dao.dart';
import '../db/database.dart';
import '../db/mixin_database.dart';
import '../utils/proxy.dart';
import 'model/ai_prompt_message.dart';
import 'model/ai_provider_config.dart';
import 'model/ai_provider_type.dart';

const _kAiRoleUser = 'user';
const _kAiRoleAssistant = 'assistant';
const _kAiStatusPending = 'pending';
const _kAiStatusDone = 'done';
const _kAiStatusError = 'error';
const _kAiContextMessageLimit = 30;
const _kAiHistoryLimit = 12;
const _kAiStreamFlushChars = 32;
const _kAiStreamFlushInterval = Duration(milliseconds: 80);
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

    final messages = await _buildAssistPromptMessages(
      instruction: instruction,
      input: input,
      conversationId: conversationId,
    );

    return _streamRequest(
      config,
      messages,
      cancelToken: CancelToken(),
      onContent: (_) async {},
    );
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
      final result = await _streamRequest(
        config,
        messages,
        cancelToken: cancelToken,
        onContent: updater.append,
      );
      await updater.flush(contentOverride: result, force: true);
      await database.aiChatMessageDao.updateMessageStatus(
        assistantMessageId,
        _kAiStatusDone,
        updatedAt: DateTime.now(),
      );
    } catch (error, stacktrace) {
      if (cancelToken.isCancelled) {
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
    _activeAiRequests[conversationId]?.cancel('AI generation stopped');
  }

  Future<List<AiPromptMessage>> _buildPromptMessages(
    String conversationId,
    String input,
  ) async {
    final recentMessages = await database.messageDao
        .messagesByConversationId(conversationId, _kAiContextMessageLimit)
        .get();
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

    if (recentMessages.isNotEmpty) {
      final lines = recentMessages.reversed
          .map((message) {
            final sender = message.userFullName ?? message.userId;
            final content = _messagePlainText(message);
            return '[${message.createdAt.toIso8601String()}] $sender: $content';
          })
          .join('\n');
      promptMessages.add(
        AiPromptMessage(
          role: 'system',
          content: 'Current conversation recent messages:\n$lines',
        ),
      );
    }

    final history = aiMessages
        .where((element) => element.status != _kAiStatusPending)
        .takeLast(_kAiHistoryLimit);
    for (final item in history) {
      promptMessages.add(
        AiPromptMessage(role: item.role, content: item.content),
      );
    }

    promptMessages.add(AiPromptMessage(role: _kAiRoleUser, content: input));
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
      final recentMessages = await database.messageDao
          .messagesByConversationId(conversationId, _kAiContextMessageLimit)
          .get();
      if (recentMessages.isNotEmpty) {
        final lines = recentMessages.reversed
            .map((message) {
              final sender = message.userFullName ?? message.userId;
              final content = _messagePlainText(message);
              return '[${message.createdAt.toIso8601String()}] $sender: $content';
            })
            .join('\n');
        promptMessages.add(
          AiPromptMessage(
            role: 'system',
            content: 'Current conversation recent messages:\n$lines',
          ),
        );
      }
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
    return promptMessages;
  }

  String _messagePlainText(MessageItem message) {
    if (message.content?.trim().isNotEmpty == true) {
      return message.content!.trim();
    }
    if (message.mediaName?.isNotEmpty == true) {
      return '[${message.type}] ${message.mediaName}';
    }
    return '[${message.type}]';
  }

  Future<String> _streamRequest(
    AiProviderConfig config,
    List<AiPromptMessage> messages, {
    required CancelToken cancelToken,
    required Future<void> Function(String chunk) onContent,
  }) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(seconds: 20),
        headers: _strategyFor(config.type).headers(config),
      ),
    )..applyProxy(database.settingProperties.activatedProxy);

    return _strategyFor(config.type).streamResponse(
      dio: dio,
      config: config,
      messages: messages,
      cancelToken: cancelToken,
      onContent: onContent,
    );
  }

  _AiProviderStrategy _strategyFor(AiProviderType type) => switch (type) {
    AiProviderType.openaiCompatible => _openAiStrategy,
    AiProviderType.anthropic => _anthropicStrategy,
  };
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
        'messages': messages
            .map(
              (message) => {'role': message.role, 'content': message.content},
            )
            .toList(),
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
            .map(
              (message) => {'role': message.role, 'content': message.content},
            )
            .toList(),
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
