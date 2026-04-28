import 'dart:convert';

import 'package:dio/dio.dart';

import '../model/ai_prompt_message.dart';
import '../model/ai_provider_config.dart';
import '../model/ai_tool.dart';
import 'ai_provider_strategy.dart';

class OpenAiCompatibleStrategy implements AiProviderStrategy {
  const OpenAiCompatibleStrategy();

  @override
  Map<String, dynamic> headers(AiProviderConfig config) => {
    'Authorization': 'Bearer ${config.apiKey}',
    'Content-Type': 'application/json',
  };

  @override
  Future<AiCompletionResponse> completeResponse({
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

    final body = AiProviderStrategySupport.jsonMap(response.data);
    final choices = body['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Empty AI response');
    }
    final first = AiProviderStrategySupport.jsonMap(choices.first);
    final message = AiProviderStrategySupport.jsonMap(first['message']);
    final text = AiProviderStrategySupport.stringContent(message['content']);
    final toolCalls = (message['tool_calls'] as List<dynamic>? ?? const [])
        .map((item) => _openAiToolCall(AiProviderStrategySupport.jsonMap(item)))
        .toList(growable: false);
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
    await for (final data in AiProviderStrategySupport.decodeSse(body.stream)) {
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
    final function = AiProviderStrategySupport.jsonMap(value['function']);
    final name = function['name'] as String?;
    if (name == null || name.isEmpty) {
      throw Exception('Invalid AI tool call name');
    }
    return AiToolCall(
      id: value['id'] as String? ?? '${name}_${value.hashCode}',
      name: name,
      arguments: AiProviderStrategySupport.toolArguments(function['arguments']),
    );
  }
}
