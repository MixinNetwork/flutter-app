import 'dart:convert';

import 'package:dio/dio.dart';

import '../model/ai_prompt_message.dart';
import '../model/ai_provider_config.dart';
import '../model/ai_tool.dart';
import 'ai_provider_strategy.dart';

class AnthropicStrategy implements AiProviderStrategy {
  const AnthropicStrategy();

  @override
  Map<String, dynamic> headers(AiProviderConfig config) => {
    'x-api-key': config.apiKey,
    'anthropic-version': '2023-06-01',
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

    final body = AiProviderStrategySupport.jsonMap(response.data);
    if (body['type'] == 'error') {
      final error = AiProviderStrategySupport.jsonMap(body['error']);
      throw Exception(error['message'] ?? 'Anthropic request failed');
    }

    final content = body['content'] as List<dynamic>?;
    if (content == null || content.isEmpty) {
      throw Exception('Empty AI response');
    }

    final textBuffer = StringBuffer();
    final toolCalls = <AiToolCall>[];
    for (final item in content) {
      final block = AiProviderStrategySupport.jsonMap(item);
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
              arguments: AiProviderStrategySupport.toolArguments(
                block['input'],
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
    await for (final data in AiProviderStrategySupport.decodeSse(body.stream)) {
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

  List<Map<String, dynamic>> _anthropicContentBlocks(
    AiPromptMessage message,
  ) {
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
