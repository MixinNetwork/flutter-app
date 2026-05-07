import 'package:genkit/genkit.dart' as genkit;

extension type AiPromptRole(String value) {
  static AiPromptRole get system => AiPromptRole('system');
  static AiPromptRole get user => AiPromptRole('user');
  static AiPromptRole get assistant => AiPromptRole('assistant');
  static AiPromptRole get tool => AiPromptRole('tool');

  genkit.Role toGenkitRole() => switch (value) {
    'system' => genkit.Role.system,
    'assistant' => genkit.Role.model,
    'tool' => genkit.Role.tool,
    _ => genkit.Role.user,
  };
}

class AiPromptMessage {
  AiPromptMessage({required this.role, required this.content});

  final AiPromptRole role;
  final String content;

  genkit.Message toGenkitMessage() => genkit.Message(
    role: role.toGenkitRole(),
    content: [genkit.TextPart(text: content)],
  );
}
