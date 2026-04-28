import 'dart:convert';
import 'dart:math' as math;

import 'package:genkit/genkit.dart' as genkit;
import 'package:mixin_logger/mixin_logger.dart';
import 'package:schemantic/schemantic.dart';
import 'package:toon_format/toon_format.dart';

import '../../db/dao/message_dao.dart';
import '../../db/database.dart';
import '../../db/mixin_database.dart';
import '../model/ai_chat_metadata.dart';

const _kDefaultConversationChunkSize = 100;
const _kMaxConversationChunkSize = 200;
const _kDefaultConversationSearchLimit = 8;
const _kMaxConversationSearchLimit = 20;
const _kAiToolLogPreviewLength = 480;

typedef AiConversationToolEventSink =
    Future<void> Function(Map<String, dynamic> event);

class AiConversationToolMessage {
  const AiConversationToolMessage({
    required this.messageId,
    required this.createdAt,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.text,
  });

  final String messageId;
  final DateTime createdAt;
  final String senderId;
  final String senderName;
  final String type;
  final String text;

  Map<String, dynamic> toJson() => {
    'message_id': messageId,
    'created_at': createdAt.toIso8601String(),
    'sender_id': senderId,
    'sender_name': senderName,
    'type': type,
    'text': text,
  };
}

class AiConversationToolStats {
  const AiConversationToolStats({
    required this.conversationId,
    required this.messageCount,
    required this.startInclusive,
    required this.endExclusive,
    this.firstMessageAt,
    this.lastMessageAt,
  });

  final String conversationId;
  final int messageCount;
  final DateTime? startInclusive;
  final DateTime? endExclusive;
  final DateTime? firstMessageAt;
  final DateTime? lastMessageAt;

  Map<String, dynamic> toJson() => {
    'conversation_id': conversationId,
    'message_count': messageCount,
    'start_time': startInclusive?.toIso8601String(),
    'end_time': endExclusive?.toIso8601String(),
    'first_message_at': firstMessageAt?.toIso8601String(),
    'last_message_at': lastMessageAt?.toIso8601String(),
  };
}

class AiConversationToolChunk {
  const AiConversationToolChunk({
    required this.index,
    required this.offset,
    required this.messageCount,
  });

  final int index;
  final int offset;
  final int messageCount;

  Map<String, dynamic> toJson() => {
    'index': index,
    'offset': offset,
    'message_count': messageCount,
  };
}

class AiConversationToolChunkList {
  const AiConversationToolChunkList({
    required this.conversationId,
    required this.chunkSize,
    required this.totalMessages,
    required this.startInclusive,
    required this.endExclusive,
    required this.chunks,
  });

  final String conversationId;
  final int chunkSize;
  final int totalMessages;
  final DateTime? startInclusive;
  final DateTime? endExclusive;
  final List<AiConversationToolChunk> chunks;

  Map<String, dynamic> toJson() => {
    'conversation_id': conversationId,
    'chunk_size': chunkSize,
    'total_messages': totalMessages,
    'total_chunks': chunks.length,
    'start_time': startInclusive?.toIso8601String(),
    'end_time': endExclusive?.toIso8601String(),
    'chunks': chunks.map((chunk) => chunk.toJson()).toList(growable: false),
  };
}

class AiConversationToolChunkPage {
  const AiConversationToolChunkPage({
    required this.conversationId,
    required this.offset,
    required this.limit,
    required this.totalMessages,
    required this.startInclusive,
    required this.endExclusive,
    required this.messages,
    required this.nextOffset,
  });

  final String conversationId;
  final int offset;
  final int limit;
  final int totalMessages;
  final DateTime? startInclusive;
  final DateTime? endExclusive;
  final List<AiConversationToolMessage> messages;
  final int? nextOffset;

  Map<String, dynamic> toJson() => {
    'conversation_id': conversationId,
    'offset': offset,
    'limit': limit,
    'total_messages': totalMessages,
    'returned_count': messages.length,
    'next_offset': nextOffset,
    'start_time': startInclusive?.toIso8601String(),
    'end_time': endExclusive?.toIso8601String(),
    'messages': messages
        .map((message) => message.toJson())
        .toList(growable: false),
  };
}

class AiConversationToolSearchResult {
  const AiConversationToolSearchResult({
    required this.conversationId,
    required this.query,
    required this.limit,
    required this.messages,
  });

  final String conversationId;
  final String query;
  final int limit;
  final List<AiConversationToolMessage> messages;

  Map<String, dynamic> toJson() => {
    'conversation_id': conversationId,
    'query': query,
    'limit': limit,
    'returned_count': messages.length,
    'messages': messages
        .map((message) => message.toJson())
        .toList(growable: false),
  };
}

abstract interface class AiConversationToolService {
  Future<AiConversationToolStats> getConversationStats({
    required String conversationId,
    DateTime? startInclusive,
    DateTime? endExclusive,
  });

  Future<AiConversationToolChunkList> listConversationChunks({
    required String conversationId,
    required int chunkSize,
    DateTime? startInclusive,
    DateTime? endExclusive,
  });

  Future<AiConversationToolChunkPage> readConversationChunk({
    required String conversationId,
    required int offset,
    required int limit,
    DateTime? startInclusive,
    DateTime? endExclusive,
  });

  Future<AiConversationToolSearchResult> searchConversationMessages({
    required String conversationId,
    required String query,
    required int limit,
  });
}

class DatabaseAiConversationToolService implements AiConversationToolService {
  DatabaseAiConversationToolService(this.database);

  final Database database;

  @override
  Future<AiConversationToolStats> getConversationStats({
    required String conversationId,
    DateTime? startInclusive,
    DateTime? endExclusive,
  }) async {
    final messageCount = await database.messageDao
        .messageCountByConversationIdAndCreatedAtRange(
          conversationId,
          startInclusive: startInclusive,
          endExclusive: endExclusive,
        )
        .getSingle();

    DateTime? firstMessageAt;
    DateTime? lastMessageAt;
    if (messageCount > 0) {
      final firstMessage = await database.messageDao
          .messagesByConversationIdAndCreatedAtRange(
            conversationId,
            limit: 1,
            startInclusive: startInclusive,
            endExclusive: endExclusive,
          )
          .getSingleOrNull();
      final lastMessage = await database.messageDao
          .messagesByConversationIdAndCreatedAtRange(
            conversationId,
            limit: 1,
            startInclusive: startInclusive,
            endExclusive: endExclusive,
            ascending: false,
          )
          .getSingleOrNull();
      firstMessageAt = firstMessage?.createdAt;
      lastMessageAt = lastMessage?.createdAt;
    }

    return AiConversationToolStats(
      conversationId: conversationId,
      messageCount: messageCount,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
      firstMessageAt: firstMessageAt,
      lastMessageAt: lastMessageAt,
    );
  }

  @override
  Future<AiConversationToolChunkList> listConversationChunks({
    required String conversationId,
    required int chunkSize,
    DateTime? startInclusive,
    DateTime? endExclusive,
  }) async {
    final totalMessages = await database.messageDao
        .messageCountByConversationIdAndCreatedAtRange(
          conversationId,
          startInclusive: startInclusive,
          endExclusive: endExclusive,
        )
        .getSingle();
    final chunks = <AiConversationToolChunk>[];
    for (var offset = 0; offset < totalMessages; offset += chunkSize) {
      final index = offset ~/ chunkSize;
      final messageCount = math.min(chunkSize, totalMessages - offset);
      chunks.add(
        AiConversationToolChunk(
          index: index,
          offset: offset,
          messageCount: messageCount,
        ),
      );
    }
    return AiConversationToolChunkList(
      conversationId: conversationId,
      chunkSize: chunkSize,
      totalMessages: totalMessages,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
      chunks: chunks,
    );
  }

  @override
  Future<AiConversationToolChunkPage> readConversationChunk({
    required String conversationId,
    required int offset,
    required int limit,
    DateTime? startInclusive,
    DateTime? endExclusive,
  }) async {
    final totalMessages = await database.messageDao
        .messageCountByConversationIdAndCreatedAtRange(
          conversationId,
          startInclusive: startInclusive,
          endExclusive: endExclusive,
        )
        .getSingle();
    final safeOffset = math.max(0, offset);
    final messages = safeOffset >= totalMessages
        ? const <MessageItem>[]
        : await database.messageDao
              .messagesByConversationIdAndCreatedAtRange(
                conversationId,
                limit: limit,
                offset: safeOffset,
                startInclusive: startInclusive,
                endExclusive: endExclusive,
              )
              .get();
    final nextOffset = safeOffset + messages.length < totalMessages
        ? safeOffset + messages.length
        : null;

    return AiConversationToolChunkPage(
      conversationId: conversationId,
      offset: safeOffset,
      limit: limit,
      totalMessages: totalMessages,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
      messages: messages.map(_messageItemToToolMessage).toList(growable: false),
      nextOffset: nextOffset,
    );
  }

  @override
  Future<AiConversationToolSearchResult> searchConversationMessages({
    required String conversationId,
    required String query,
    required int limit,
  }) async {
    final messages = await database.fuzzySearchMessage(
      query: query,
      limit: limit,
      conversationIds: [conversationId],
    );
    return AiConversationToolSearchResult(
      conversationId: conversationId,
      query: query,
      limit: limit,
      messages: messages
          .map(_searchMessageToToolMessage)
          .toList(growable: false),
    );
  }

  AiConversationToolMessage _messageItemToToolMessage(MessageItem message) =>
      AiConversationToolMessage(
        messageId: message.messageId,
        createdAt: message.createdAt,
        senderId: message.userId,
        senderName: message.userFullName ?? message.userId,
        type: message.type,
        text: _messageText(
          content: message.content,
          mediaName: message.mediaName,
          type: message.type,
        ),
      );

  AiConversationToolMessage _searchMessageToToolMessage(
    SearchMessageDetailItem message,
  ) => AiConversationToolMessage(
    messageId: message.messageId,
    createdAt: message.createdAt,
    senderId: message.senderId,
    senderName: message.senderFullName ?? message.senderId,
    type: message.type,
    text: _messageText(
      content: message.content,
      mediaName: message.mediaName,
      type: message.type,
    ),
  );

  String _messageText({
    required String? content,
    required String? mediaName,
    required String type,
  }) {
    if (content?.trim().isNotEmpty == true) {
      return content!.trim();
    }
    if (mediaName?.isNotEmpty == true) {
      return '[$type] $mediaName';
    }
    return '[$type]';
  }
}

class AiConversationToolKit {
  const AiConversationToolKit(this.service);

  final AiConversationToolService service;

  List<genkit.Tool> genkitTools({
    required String conversationId,
    AiConversationToolEventSink? onEvent,
  }) => [
    genkit.Tool<GetConversationStatsInput, String>(
      name: 'get_conversation_stats',
      description:
          'Get message counts and boundary timestamps for the current conversation or a specific time range.',
      inputSchema: GetConversationStatsInput.schema,
      fn: (input, context) => _executeTool(
        conversationId: conversationId,
        name: 'get_conversation_stats',
        arguments: input.toArguments(),
        context: context,
        onEvent: onEvent,
        fn: () async {
          final stats = await service.getConversationStats(
            conversationId: conversationId,
            startInclusive: input.startInclusive,
            endExclusive: input.endExclusive,
          );
          return stats.toJson();
        },
      ),
    ),
    genkit.Tool<ListConversationChunksInput, String>(
      name: 'list_conversation_chunks',
      description:
          'List chunk offsets that can be used to read the current conversation in fixed-size batches, optionally scoped to a time range.',
      inputSchema: ListConversationChunksInput.schema,
      fn: (input, context) => _executeTool(
        conversationId: conversationId,
        name: 'list_conversation_chunks',
        arguments: input.toArguments(),
        context: context,
        onEvent: onEvent,
        fn: () async {
          final chunks = await service.listConversationChunks(
            conversationId: conversationId,
            chunkSize: input.chunkSize,
            startInclusive: input.startInclusive,
            endExclusive: input.endExclusive,
          );
          return chunks.toJson();
        },
      ),
    ),
    genkit.Tool<ReadConversationChunkInput, String>(
      name: 'read_conversation_chunk',
      description:
          'Read a batch of messages from the current conversation by offset and limit, optionally scoped to a time range.',
      inputSchema: ReadConversationChunkInput.schema,
      fn: (input, context) => _executeTool(
        conversationId: conversationId,
        name: 'read_conversation_chunk',
        arguments: input.toArguments(),
        context: context,
        onEvent: onEvent,
        fn: () async {
          final page = await service.readConversationChunk(
            conversationId: conversationId,
            offset: input.offset,
            limit: input.limit,
            startInclusive: input.startInclusive,
            endExclusive: input.endExclusive,
          );
          return page.toJson();
        },
      ),
    ),
    genkit.Tool<SearchConversationMessagesInput, String>(
      name: 'search_conversation_messages',
      description:
          'Search the current conversation for messages relevant to a query string.',
      inputSchema: SearchConversationMessagesInput.schema,
      fn: (input, context) => _executeTool(
        conversationId: conversationId,
        name: 'search_conversation_messages',
        arguments: input.toArguments(),
        context: context,
        onEvent: onEvent,
        fn: () async {
          final result = await service.searchConversationMessages(
            conversationId: conversationId,
            query: input.query,
            limit: input.limit,
          );
          return result.toJson();
        },
      ),
    ),
  ];

  Future<String> _executeTool<Input>({
    required String conversationId,
    required String name,
    required Map<String, dynamic> arguments,
    required genkit.ToolFnArgs<Input> context,
    required Future<Map<String, dynamic>> Function() fn,
    required AiConversationToolEventSink? onEvent,
  }) async {
    final request = context.toolRequest?.toolRequest;
    final id = request?.ref ?? '${name}_${arguments.hashCode}';
    final stopwatch = Stopwatch()..start();
    d(
      'AI tool execute start: conversationId=$conversationId '
      'tool=$name id=$id arguments=${_previewJson(arguments)}',
    );
    await onEvent?.call(
      createAiToolCallEvent(id: id, name: name, arguments: arguments),
    );
    try {
      final result = await fn();
      final encodedResult = _encodeToolResult(result);
      d(
        'AI tool execute done: conversationId=$conversationId '
        'tool=$name id=$id elapsedMs=${stopwatch.elapsedMilliseconds} '
        'result=${_previewText(encodedResult)}',
      );
      await onEvent?.call(
        createAiToolResultEvent(
          id: id,
          name: name,
          status: 'done',
          elapsedMs: stopwatch.elapsedMilliseconds,
          resultPreview: _previewText(encodedResult),
        ),
      );
      return encodedResult;
    } catch (error, stacktrace) {
      e('AI tool execution error: $error, $stacktrace');
      await onEvent?.call(
        createAiToolResultEvent(
          id: id,
          name: name,
          status: 'error',
          elapsedMs: stopwatch.elapsedMilliseconds,
          errorText: error.toString(),
        ),
      );
      return _encodeToolResult({'error': '$error'});
    }
  }
}

class GetConversationStatsInput {
  const GetConversationStatsInput({
    this.startInclusive,
    this.endExclusive,
  });

  final DateTime? startInclusive;
  final DateTime? endExclusive;

  static final schema = SchemanticType.from<GetConversationStatsInput>(
    jsonSchema: _rangeSchema(),
    parse: (value) {
      final arguments = _jsonMap(value);
      final (startInclusive, endExclusive) = _parseRange(arguments);
      return GetConversationStatsInput(
        startInclusive: startInclusive,
        endExclusive: endExclusive,
      );
    },
  );

  Map<String, dynamic> toArguments() => {
    'start_time': startInclusive?.toIso8601String(),
    'end_time': endExclusive?.toIso8601String(),
  }..removeWhere((_, value) => value == null);
}

class ListConversationChunksInput {
  const ListConversationChunksInput({
    required this.chunkSize,
    this.startInclusive,
    this.endExclusive,
  });

  final int chunkSize;
  final DateTime? startInclusive;
  final DateTime? endExclusive;

  static final schema = SchemanticType.from<ListConversationChunksInput>(
    jsonSchema: _rangeSchema(
      properties: {
        'chunk_size': {
          'type': 'integer',
          'description': 'Optional chunk size between 1 and 200.',
        },
      },
    ),
    parse: (value) {
      final arguments = _jsonMap(value);
      final (startInclusive, endExclusive) = _parseRange(arguments);
      return ListConversationChunksInput(
        chunkSize: _parseInt(
          arguments,
          'chunk_size',
          defaultValue: _kDefaultConversationChunkSize,
          min: 1,
          max: _kMaxConversationChunkSize,
        ),
        startInclusive: startInclusive,
        endExclusive: endExclusive,
      );
    },
  );

  Map<String, dynamic> toArguments() => {
    'chunk_size': chunkSize,
    'start_time': startInclusive?.toIso8601String(),
    'end_time': endExclusive?.toIso8601String(),
  }..removeWhere((_, value) => value == null);
}

class ReadConversationChunkInput {
  const ReadConversationChunkInput({
    required this.offset,
    required this.limit,
    this.startInclusive,
    this.endExclusive,
  });

  final int offset;
  final int limit;
  final DateTime? startInclusive;
  final DateTime? endExclusive;

  static final schema = SchemanticType.from<ReadConversationChunkInput>(
    jsonSchema: _rangeSchema(
      properties: {
        'offset': {
          'type': 'integer',
          'description': 'Zero-based offset into the matching message list.',
        },
        'limit': {
          'type': 'integer',
          'description': 'Number of messages to read, between 1 and 200.',
        },
      },
      required: ['offset'],
    ),
    parse: (value) {
      final arguments = _jsonMap(value);
      final (startInclusive, endExclusive) = _parseRange(arguments);
      return ReadConversationChunkInput(
        offset: _parseInt(
          arguments,
          'offset',
          defaultValue: 0,
          min: 0,
          max: 1 << 20,
        ),
        limit: _parseInt(
          arguments,
          'limit',
          defaultValue: _kDefaultConversationChunkSize,
          min: 1,
          max: _kMaxConversationChunkSize,
        ),
        startInclusive: startInclusive,
        endExclusive: endExclusive,
      );
    },
  );

  Map<String, dynamic> toArguments() => {
    'offset': offset,
    'limit': limit,
    'start_time': startInclusive?.toIso8601String(),
    'end_time': endExclusive?.toIso8601String(),
  }..removeWhere((_, value) => value == null);
}

class SearchConversationMessagesInput {
  const SearchConversationMessagesInput({
    required this.query,
    required this.limit,
  });

  final String query;
  final int limit;

  static final schema = SchemanticType.from<SearchConversationMessagesInput>(
    jsonSchema: {
      'type': 'object',
      'properties': {
        'query': {
          'type': 'string',
          'description': 'Search query text.',
        },
        'limit': {
          'type': 'integer',
          'description':
              'Maximum number of matches to return, between 1 and 20.',
        },
      },
      'required': ['query'],
      'additionalProperties': false,
    },
    parse: (value) {
      final arguments = _jsonMap(value);
      return SearchConversationMessagesInput(
        query: _parseRequiredString(arguments, 'query'),
        limit: _parseInt(
          arguments,
          'limit',
          defaultValue: _kDefaultConversationSearchLimit,
          min: 1,
          max: _kMaxConversationSearchLimit,
        ),
      );
    },
  );

  Map<String, dynamic> toArguments() => {
    'query': query,
    'limit': limit,
  };
}

Map<String, Object?> _rangeSchema({
  Map<String, Object?> properties = const {},
  List<String> required = const [],
}) => {
  'type': 'object',
  'properties': {
    'start_time': {
      'type': 'string',
      'description': 'Optional inclusive ISO-8601 start time.',
    },
    'end_time': {
      'type': 'string',
      'description': 'Optional exclusive ISO-8601 end time.',
    },
    ...properties,
  },
  if (required.isNotEmpty) 'required': required,
  'additionalProperties': false,
};

(DateTime?, DateTime?) _parseRange(Map<String, dynamic> arguments) {
  final startInclusive = _parseDateTime(arguments, 'start_time');
  final endExclusive = _parseDateTime(arguments, 'end_time');
  if (startInclusive != null &&
      endExclusive != null &&
      !endExclusive.isAfter(startInclusive)) {
    throw const FormatException('end_time must be later than start_time');
  }
  return (startInclusive, endExclusive);
}

DateTime? _parseDateTime(Map<String, dynamic> arguments, String key) {
  final raw = arguments[key];
  if (raw == null) {
    return null;
  }
  if (raw is! String || raw.trim().isEmpty) {
    throw FormatException('$key must be an ISO-8601 string');
  }
  final value = DateTime.tryParse(raw.trim());
  if (value == null) {
    throw FormatException('$key must be a valid ISO-8601 string');
  }
  return value;
}

int _parseInt(
  Map<String, dynamic> arguments,
  String key, {
  required int defaultValue,
  required int min,
  required int max,
}) {
  final raw = arguments[key];
  if (raw == null) {
    return defaultValue;
  }
  final value = switch (raw) {
    final int value => value,
    final String value =>
      int.tryParse(value.trim()) ??
          (throw FormatException('$key must be an integer')),
    _ => throw FormatException('$key must be an integer'),
  };
  return value.clamp(min, max);
}

String _parseRequiredString(Map<String, dynamic> arguments, String key) {
  final raw = arguments[key];
  if (raw is! String || raw.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string');
  }
  return raw.trim();
}

Map<String, dynamic> _jsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry('$key', value));
  }
  throw Exception('Invalid AI tool arguments');
}

String _previewJson(Object? value) {
  try {
    final encoded = jsonEncode(value);
    if (encoded.length <= _kAiToolLogPreviewLength) {
      return encoded;
    }
    return '${encoded.substring(0, _kAiToolLogPreviewLength)}...(${encoded.length} chars)';
  } catch (_) {
    return '$value';
  }
}

String _encodeToolResult(Map<String, dynamic> result) =>
    encode(_stripNullValues(result));

Object? _stripNullValues(Object? value) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        if (entry.value != null) entry.key: _stripNullValues(entry.value),
    };
  }
  if (value is List) {
    return value.map(_stripNullValues).toList(growable: false);
  }
  return value;
}

String _previewText(String value) {
  final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.length <= _kAiToolLogPreviewLength) {
    return compact;
  }
  return '${compact.substring(0, _kAiToolLogPreviewLength)}...(${compact.length} chars)';
}
