import 'dart:convert';

import 'ai_provider_config.dart';

const aiMetadataToolEventsKey = 'toolEvents';
const aiMetadataResponseKey = 'response';
const aiToolEventTypeCall = 'tool_call';
const aiToolEventTypeResult = 'tool_result';

String createAiMessageMetadata(AiProviderConfig provider) => jsonEncode({
  'provider': {
    'id': provider.id,
    'type': provider.type.name,
    'model': provider.model,
  },
  aiMetadataToolEventsKey: const <Map<String, dynamic>>[],
});

Map<String, dynamic> decodeAiMessageMetadata(String? metadata) {
  if (metadata == null || metadata.trim().isEmpty) {
    return <String, dynamic>{};
  }
  try {
    final decoded = jsonDecode(metadata);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry('$key', value));
    }
  } catch (_) {
    return <String, dynamic>{};
  }
  return <String, dynamic>{};
}

String appendAiToolEventToMetadata(
  String? metadata,
  Map<String, dynamic> event,
) {
  final root = decodeAiMessageMetadata(metadata);
  final currentEvents = root[aiMetadataToolEventsKey];
  final events = currentEvents is List
      ? currentEvents.toList(growable: true)
      : <dynamic>[];
  root[aiMetadataToolEventsKey] = events..add(event);
  return jsonEncode(root);
}

String setAiResponseMetadata(
  String? metadata,
  Map<String, dynamic> responseMetadata,
) {
  final root = decodeAiMessageMetadata(metadata);
  root[aiMetadataResponseKey] = responseMetadata;
  return jsonEncode(root);
}

Map<String, dynamic> createAiResponseMetadata({
  required int elapsedMs,
  required int promptMessageCount,
  required int toolCount,
  required int outputCharacters,
  required Map<String, dynamic> response,
}) => <String, dynamic>{
  'elapsedMs': elapsedMs,
  'promptMessageCount': promptMessageCount,
  'toolCount': toolCount,
  'outputCharacters': outputCharacters,
  'completedAt': DateTime.now().toUtc().toIso8601String(),
  ...response,
}..removeWhere((_, value) => value == null);

Map<String, dynamic> aiMetadataResponse(String? metadata) {
  final response = decodeAiMessageMetadata(metadata)[aiMetadataResponseKey];
  if (response is Map<String, dynamic>) {
    return response;
  }
  if (response is Map) {
    return response.map((key, value) => MapEntry('$key', value));
  }
  return const <String, dynamic>{};
}

Map<String, dynamic> createAiToolCallEvent({
  required String id,
  required String name,
  required Map<String, dynamic> arguments,
}) => {
  'type': aiToolEventTypeCall,
  'id': id,
  'name': name,
  'arguments': arguments,
  'createdAt': DateTime.now().toUtc().toIso8601String(),
};

Map<String, dynamic> createAiToolResultEvent({
  required String id,
  required String name,
  required String status,
  required int elapsedMs,
  String? resultPreview,
  String? errorText,
}) => <String, dynamic>{
  'type': aiToolEventTypeResult,
  'id': id,
  'name': name,
  'status': status,
  'elapsedMs': elapsedMs,
  'resultPreview': resultPreview,
  'errorText': errorText,
  'createdAt': DateTime.now().toUtc().toIso8601String(),
}..removeWhere((_, value) => value == null);

List<Map<String, dynamic>> aiMetadataToolEvents(String? metadata) {
  final events = decodeAiMessageMetadata(metadata)[aiMetadataToolEventsKey];
  if (events is! List) {
    return const <Map<String, dynamic>>[];
  }
  return events
      .whereType<Map>()
      .map((event) => event.map((key, value) => MapEntry('$key', value)))
      .toList(growable: false);
}
