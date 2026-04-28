import 'dart:convert';

import 'package:flutter_app/ai/model/ai_chat_metadata.dart';
import 'package:flutter_app/ai/model/ai_provider_config.dart';
import 'package:flutter_app/ai/model/ai_provider_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AI chat metadata', () {
    test('keeps provider and tool events when response metadata is set', () {
      final initialMetadata = createAiMessageMetadata(
        AiProviderConfig(
          id: 'provider-id',
          name: 'Provider',
          type: AiProviderType.openaiCompatible,
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'key',
          model: 'test-model',
        ),
      );
      final withToolEvent = appendAiToolEventToMetadata(
        initialMetadata,
        createAiToolCallEvent(
          id: 'tool-id',
          name: 'read_conversation_chunk',
          arguments: const {'limit': 20},
        ),
      );

      final updated = setAiResponseMetadata(
        withToolEvent,
        createAiResponseMetadata(
          elapsedMs: 1234,
          promptMessageCount: 7,
          toolCount: 4,
          outputCharacters: 42,
          response: const {
            'finishReason': 'stop',
            'usage': {
              'inputTokens': 100,
              'outputTokens': 24,
              'totalTokens': 124,
            },
          },
        ),
      );

      final decoded = jsonDecode(updated) as Map<String, dynamic>;
      expect(decoded['provider'], isA<Map<String, dynamic>>());
      expect(aiMetadataToolEvents(updated), hasLength(1));
      expect(aiMetadataResponse(updated), containsPair('elapsedMs', 1234));
      expect(
        aiMetadataResponse(updated),
        containsPair('promptMessageCount', 7),
      );
      expect(
        aiMetadataResponse(updated)['usage'],
        containsPair('totalTokens', 124),
      );
    });
  });
}
