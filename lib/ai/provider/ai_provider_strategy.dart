import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../model/ai_prompt_message.dart';
import '../model/ai_provider_config.dart';
import '../model/ai_tool.dart';

abstract interface class AiProviderStrategy {
  const AiProviderStrategy();

  Map<String, dynamic> headers(AiProviderConfig config);

  Future<AiCompletionResponse> completeResponse({
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

class AiCompletionResponse {
  const AiCompletionResponse({
    this.text = '',
    this.toolCalls = const [],
  });

  final String text;
  final List<AiToolCall> toolCalls;

  bool get hasToolCalls => toolCalls.isNotEmpty;
}

final class AiProviderStrategySupport {
  const AiProviderStrategySupport._();

  static Map<String, dynamic> jsonMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry('$key', value));
    }
    throw Exception('Invalid AI response payload');
  }

  static Map<String, dynamic> toolArguments(dynamic value) {
    if (value == null) {
      return const {};
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return const {};
      }
      final decoded = jsonDecode(trimmed);
      return jsonMap(decoded);
    }
    return jsonMap(value);
  }

  static String stringContent(dynamic value) {
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

  static Stream<String> decodeSse(Stream<List<int>> stream) async* {
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
}
