import 'ai_tool.dart';

class AiPromptMessage {
  AiPromptMessage({
    required this.role,
    required this.content,
    List<AiToolCall>? toolCalls,
    this.toolCallId,
    this.toolName,
    this.toolPayload,
  }) : toolCalls = toolCalls ?? const [];

  final String role;
  final String content;
  final List<AiToolCall> toolCalls;
  final String? toolCallId;
  final String? toolName;
  final Map<String, dynamic>? toolPayload;

  bool get hasToolCalls => toolCalls.isNotEmpty;

  bool get isToolResult => role == 'tool';
}
