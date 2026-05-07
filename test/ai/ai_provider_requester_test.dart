import 'package:dio/dio.dart';
import 'package:flutter_app/ai/ai_provider_requester.dart';
import 'package:flutter_app/ai/model/ai_prompt_message.dart';
import 'package:flutter_app/ai/model/ai_provider_config.dart';
import 'package:flutter_app/ai/model/ai_provider_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart' as genkit;

void main() {
  group('AI provider requester', () {
    test('maps prompt messages to Genkit messages', () {
      final userMessage = AiPromptMessage(
        role: AiPromptRole.user,
        content: 'hello',
      ).toGenkitMessage();
      final assistantMessage = AiPromptMessage(
        role: AiPromptRole.assistant,
        content: 'hi',
      ).toGenkitMessage();
      final systemMessage = AiPromptMessage(
        role: AiPromptRole.system,
        content: 'rules',
      ).toGenkitMessage();
      final unknownMessage = AiPromptMessage(
        role: AiPromptRole('unknown'),
        content: 'fallback',
      ).toGenkitMessage();

      expect(userMessage.role, genkit.Role.user);
      expect(userMessage.text, 'hello');
      expect(assistantMessage.role, genkit.Role.model);
      expect(assistantMessage.text, 'hi');
      expect(systemMessage.role, genkit.Role.system);
      expect(systemMessage.text, 'rules');
      expect(unknownMessage.role, genkit.Role.user);
      expect(unknownMessage.text, 'fallback');
    });

    test('throws before creating a request when cancelled', () async {
      final cancelToken = CancelToken()..cancel('stopped');

      await expectLater(
        const AiProviderRequester().requestText(
          AiProviderConfig(
            id: 'provider-id',
            name: 'Provider',
            type: AiProviderType.openaiCompatible,
            baseUrl: 'https://api.example.com/v1',
            apiKey: 'key',
            model: 'test-model',
          ),
          [
            AiPromptMessage(role: AiPromptRole.user, content: 'hello'),
          ],
          proxy: null,
          cancelToken: cancelToken,
          onContent: (_) async {},
          conversationId: null,
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('AI generation stopped'),
          ),
        ),
      );
    });
  });
}
