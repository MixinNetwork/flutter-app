import 'dart:convert';

import 'package:dio/dio.dart';

import '../model/ai_prompt_message.dart';
import '../model/ai_provider_config.dart';
import '../model/ai_tool.dart';
import 'ai_provider_strategy.dart';

class GeminiStrategy implements AiProviderStrategy {
  const GeminiStrategy();

  @override
  Map<String, dynamic> headers(AiProviderConfig config) => {
    'x-goog-api-key': config.apiKey,
    'content-type': 'application/json',
  };

  @override
  Future<AiCompletionResponse> completeResponse({
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

    final body = AiProviderStrategySupport.jsonMap(response.data);
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
    final first = AiProviderStrategySupport.jsonMap(candidates.first);
    final finishReason = first['finishReason'];
    if (finishReason is String &&
        finishReason.isNotEmpty &&
        finishReason != 'STOP' &&
        finishReason != 'FINISH_REASON_UNSPECIFIED') {
      throw Exception('Gemini request finished with reason: $finishReason');
    }

    final content = AiProviderStrategySupport.jsonMap(first['content']);
    final parts = content['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Empty AI response');
    }

    final textBuffer = StringBuffer();
    final toolCalls = <AiToolCall>[];
    for (final item in parts) {
      final part = AiProviderStrategySupport.jsonMap(item);
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
            arguments: AiProviderStrategySupport.toolArguments(
              functionCall['args'],
            ),
          ),
        );
      }
    }

    final text = textBuffer.toString();
    if (text.trim().isEmpty && toolCalls.isEmpty) {
      throw Exception('Empty AI response');
    }
    return AiCompletionResponse(text: text, toolCalls: toolCalls);
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
    await for (final data in AiProviderStrategySupport.decodeSse(body.stream)) {
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
    'role': message.role == 'assistant' ? 'model' : 'user',
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
