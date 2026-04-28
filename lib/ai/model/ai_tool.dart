import 'dart:convert';

class AiToolDefinition {
  const AiToolDefinition({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
}

class AiToolCall {
  const AiToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  final String id;
  final String name;
  final Map<String, dynamic> arguments;
}

class AiToolExecutionResult {
  const AiToolExecutionResult({
    required this.toolCallId,
    required this.toolName,
    required this.payload,
  });

  final String toolCallId;
  final String toolName;
  final Map<String, dynamic> payload;

  String get content => jsonEncode(payload);
}
