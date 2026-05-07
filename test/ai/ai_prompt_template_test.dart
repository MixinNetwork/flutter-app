import 'package:flutter_app/ai/model/ai_prompt_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AI prompt template', () {
    test('renders known variables', () {
      final result = renderAiPromptTemplate(
        'Conversation {{conversationId}} at {{currentIsoDateTime}} in {{language}} -> {{input}}',
        buildAiPromptTemplateVariables(
          conversationId: 'conversation-1',
          input: 'hello',
          language: 'zh-CN',
          now: DateTime(2026, 4, 28, 9, 30, 15),
        ),
      );

      expect(
        result,
        'Conversation conversation-1 at 2026-04-28T09:30:15.000 in zh-CN -> hello',
      );
    });

    test('renders legacy date aliases for backwards compatibility', () {
      final result = renderAiPromptTemplate(
        '{{currentDate}} {{currentTime}} {{currentDateTime}}',
        buildAiPromptTemplateVariables(
          now: DateTime(2026, 4, 28, 9, 30, 15),
        ),
      );

      expect(result, '2026-04-28 09:30:15 2026-04-28 09:30:15');
    });

    test('keeps unknown variables unchanged', () {
      final result = renderAiPromptTemplate(
        'Known={{input}} Unknown={{customValue}}',
        buildAiPromptTemplateVariables(input: 'hello'),
      );

      expect(result, 'Known=hello Unknown={{customValue}}');
    });

    test('builds input section only when input exists', () {
      expect(buildAiPromptInputSection('  hello  '), '\nText:\nhello');
      expect(buildAiPromptInputSection('   '), isEmpty);
      expect(buildAiPromptInputSection(null), isEmpty);
    });
  });
}
