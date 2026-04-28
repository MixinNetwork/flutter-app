import 'dart:math' as math;

import '../../db/dao/message_dao.dart';
import '../../db/database.dart';
import '../../db/mixin_database.dart';
import '../model/ai_tool.dart';

const _kDefaultConversationChunkSize = 100;
const _kMaxConversationChunkSize = 200;
const _kDefaultConversationSearchLimit = 8;
const _kMaxConversationSearchLimit = 20;

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

  static const definitions = <AiToolDefinition>[
    AiToolDefinition(
      name: 'get_conversation_stats',
      description:
          'Get message counts and boundary timestamps for the current conversation or a specific time range.',
      inputSchema: {
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
        },
        'additionalProperties': false,
      },
    ),
    AiToolDefinition(
      name: 'list_conversation_chunks',
      description:
          'List chunk offsets that can be used to read the current conversation in fixed-size batches, optionally scoped to a time range.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'chunk_size': {
            'type': 'integer',
            'description': 'Optional chunk size between 1 and 200.',
          },
          'start_time': {
            'type': 'string',
            'description': 'Optional inclusive ISO-8601 start time.',
          },
          'end_time': {
            'type': 'string',
            'description': 'Optional exclusive ISO-8601 end time.',
          },
        },
        'additionalProperties': false,
      },
    ),
    AiToolDefinition(
      name: 'read_conversation_chunk',
      description:
          'Read a batch of messages from the current conversation by offset and limit, optionally scoped to a time range.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'offset': {
            'type': 'integer',
            'description': 'Zero-based offset into the matching message list.',
          },
          'limit': {
            'type': 'integer',
            'description': 'Number of messages to read, between 1 and 200.',
          },
          'start_time': {
            'type': 'string',
            'description': 'Optional inclusive ISO-8601 start time.',
          },
          'end_time': {
            'type': 'string',
            'description': 'Optional exclusive ISO-8601 end time.',
          },
        },
        'required': ['offset'],
        'additionalProperties': false,
      },
    ),
    AiToolDefinition(
      name: 'search_conversation_messages',
      description:
          'Search the current conversation for messages relevant to a query string.',
      inputSchema: {
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
    ),
  ];

  Future<AiToolExecutionResult> execute({
    required String conversationId,
    required AiToolCall call,
  }) async {
    final arguments = call.arguments;
    switch (call.name) {
      case 'get_conversation_stats':
        final (startInclusive, endExclusive) = _parseRange(arguments);
        final stats = await service.getConversationStats(
          conversationId: conversationId,
          startInclusive: startInclusive,
          endExclusive: endExclusive,
        );
        return AiToolExecutionResult(
          toolCallId: call.id,
          toolName: call.name,
          payload: stats.toJson(),
        );
      case 'list_conversation_chunks':
        final (startInclusive, endExclusive) = _parseRange(arguments);
        final chunkSize = _parseInt(
          arguments,
          'chunk_size',
          defaultValue: _kDefaultConversationChunkSize,
          min: 1,
          max: _kMaxConversationChunkSize,
        );
        final chunks = await service.listConversationChunks(
          conversationId: conversationId,
          chunkSize: chunkSize,
          startInclusive: startInclusive,
          endExclusive: endExclusive,
        );
        return AiToolExecutionResult(
          toolCallId: call.id,
          toolName: call.name,
          payload: chunks.toJson(),
        );
      case 'read_conversation_chunk':
        final (startInclusive, endExclusive) = _parseRange(arguments);
        final offset = _parseInt(
          arguments,
          'offset',
          defaultValue: 0,
          min: 0,
          max: 1 << 20,
        );
        final limit = _parseInt(
          arguments,
          'limit',
          defaultValue: _kDefaultConversationChunkSize,
          min: 1,
          max: _kMaxConversationChunkSize,
        );
        final page = await service.readConversationChunk(
          conversationId: conversationId,
          offset: offset,
          limit: limit,
          startInclusive: startInclusive,
          endExclusive: endExclusive,
        );
        return AiToolExecutionResult(
          toolCallId: call.id,
          toolName: call.name,
          payload: page.toJson(),
        );
      case 'search_conversation_messages':
        final query = _parseRequiredString(arguments, 'query');
        final limit = _parseInt(
          arguments,
          'limit',
          defaultValue: _kDefaultConversationSearchLimit,
          min: 1,
          max: _kMaxConversationSearchLimit,
        );
        final result = await service.searchConversationMessages(
          conversationId: conversationId,
          query: query,
          limit: limit,
        );
        return AiToolExecutionResult(
          toolCallId: call.id,
          toolName: call.name,
          payload: result.toJson(),
        );
      default:
        throw UnsupportedError('Unknown conversation tool: ${call.name}');
    }
  }

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
}
