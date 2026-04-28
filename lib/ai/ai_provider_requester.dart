import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../utils/proxy.dart';
import 'model/ai_prompt_message.dart';
import 'model/ai_provider_config.dart';
import 'model/ai_provider_type.dart';
import 'model/ai_tool.dart';
import 'provider/ai_provider_strategy.dart';
import 'provider/anthropic_strategy.dart';
import 'provider/gemini_strategy.dart';
import 'provider/openai_compatible_strategy.dart';
import 'tools/ai_conversation_tool_service.dart';

class AiProviderRequester {
  const AiProviderRequester();

  static const _aiToolMaxRounds = 8;
  static const _aiStreamFlushChars = 32;
  static const _aiLogPreviewLength = 240;
  static const _aiLogJsonPreviewLength = 480;

  static const _openAiStrategy = OpenAiCompatibleStrategy();
  static const _anthropicStrategy = AnthropicStrategy();
  static const _geminiStrategy = GeminiStrategy();

  Future<String> requestText(
    AiProviderConfig config,
    List<AiPromptMessage> messages, {
    required ProxyConfig? proxy,
    required CancelToken cancelToken,
    required Future<void> Function(String chunk) onContent,
    required String? conversationId,
    Future<AiToolExecutionResult> Function(AiToolCall toolCall)? onToolCall,
  }) async {
    d(
      'AI request start: provider=${config.type.name} model=${config.model} '
      'conversationId=$conversationId messages=${messages.length} '
      'tools=${conversationId != null && onToolCall != null}',
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
                  '${response.requestOptions.uri} '
                  'status=${response.statusCode} '
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
          ..applyProxy(proxy);

    if (conversationId == null || onToolCall == null) {
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
      onToolCall: onToolCall,
    );
  }

  Future<String> _requestWithTools(
    Dio dio,
    AiProviderConfig config,
    List<AiPromptMessage> messages, {
    required String conversationId,
    required CancelToken cancelToken,
    required Future<void> Function(String chunk) onContent,
    required Future<AiToolExecutionResult> Function(AiToolCall toolCall)
    onToolCall,
  }) async {
    for (var round = 0; round < _aiToolMaxRounds; round++) {
      d(
        'AI tool round start: conversationId=$conversationId '
        'round=${round + 1}/$_aiToolMaxRounds messages=${messages.length}',
      );
      final strategy = _strategyFor(config.type);
      final response = strategy is OpenAiCompatibleStrategy
          ? await strategy.streamCompleteResponse(
              dio: dio,
              config: config,
              messages: messages,
              tools: AiConversationToolKit.definitions,
              cancelToken: cancelToken,
              onContent: onContent,
            )
          : await strategy.completeResponse(
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
        if (!response.contentEmitted) {
          await _emitBufferedText(text, onContent);
        }
        d(
          'AI tool request done: '
          'conversationId=$conversationId '
          'round=${round + 1} text=${_previewText(text)}',
        );
        return text;
      }

      messages.add(
        AiPromptMessage(
          role: 'assistant',
          content: response.text,
          toolCalls: response.toolCalls,
        ),
      );
      for (final toolCall in response.toolCalls) {
        final result = await onToolCall(toolCall);
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
      'maxRounds=$_aiToolMaxRounds',
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
    if (trimmed.length <= _aiStreamFlushChars) {
      await onContent(trimmed);
      return;
    }
    for (var start = 0; start < trimmed.length; start += _aiStreamFlushChars) {
      final end = (start + _aiStreamFlushChars).clamp(0, trimmed.length);
      await onContent(trimmed.substring(start, end));
    }
  }

  AiProviderStrategy _strategyFor(AiProviderType type) => switch (type) {
    AiProviderType.openaiCompatible => _openAiStrategy,
    AiProviderType.anthropic => _anthropicStrategy,
    AiProviderType.gemini => _geminiStrategy,
  };
}

String _previewText(
  String? text, {
  int maxLength = AiProviderRequester._aiLogPreviewLength,
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

String _previewJson(
  Object? value, {
  int maxLength = AiProviderRequester._aiLogJsonPreviewLength,
}) {
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
            '${toolCall.name}#${toolCall.id}('
            '${_previewJson(toolCall.arguments, maxLength: 120)})',
      )
      .join(', ');
}
