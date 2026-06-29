import 'dart:convert';
import 'dart:math' as math;

import 'package:genkit/genkit.dart' as genkit;
import 'package:mixin_logger/mixin_logger.dart';
import 'package:schemantic/schemantic.dart';
import 'package:toon_format/toon_format.dart';

import '../../db/dao/message_dao.dart';
import '../../db/database.dart';
import '../../db/extension/message_category.dart';
import '../../db/mixin_database.dart';
import '../ai_message_context.dart';
import '../model/ai_chat_metadata.dart';
import 'ai_image_ocr_service.dart';

const _kDefaultConversationChunkSize = 100;
const _kMaxConversationChunkSize = 200;
const _kDefaultConversationSearchLimit = 8;
const _kMaxConversationSearchLimit = 20;
const _kSearchContextBeforeLimit = 2;
const _kSearchContextAfterLimit = 2;
const _kSearchQuotedByLimit = 3;
const _kAiToolLogPreviewLength = 480;
const _kMaxConversationMessageTextLength = 1000;
const _kSearchMessageSnippetRadius = 240;

typedef AiConversationToolEventSink =
    Future<void> Function(Map<String, dynamic> event);

class AiConversationToolMessage {
  const AiConversationToolMessage({
    required this.messageId,
    required this.createdAt,
    required this.senderName,
    required this.type,
    required this.text,
    this.quotedMessage,
    this.contextMessages = const [],
    this.quotedByMessages = const [],
  });

  final String messageId;
  final DateTime createdAt;
  final String senderName;
  final String type;
  final String text;
  final Map<String, dynamic>? quotedMessage;
  final List<Map<String, dynamic>> contextMessages;
  final List<Map<String, dynamic>> quotedByMessages;

  Map<String, dynamic> toJson() => {
    'message_id': messageId,
    'created_at': _formatToolDateTime(createdAt),
    'sender_name': senderName,
    'type': type,
    'text': text,
    if (quotedMessage != null) 'quoted_message': quotedMessage,
    if (contextMessages.isNotEmpty) 'context_messages': contextMessages,
    if (quotedByMessages.isNotEmpty) 'quoted_by_messages': quotedByMessages,
  };
}

class AiConversationToolStats {
  const AiConversationToolStats({
    required this.messageCount,
    this.firstMessageAt,
    this.lastMessageAt,
  });

  final int messageCount;
  final DateTime? firstMessageAt;
  final DateTime? lastMessageAt;

  Map<String, dynamic> toJson() => {
    'message_count': messageCount,
    'first_message_at': firstMessageAt == null
        ? null
        : _formatToolDateTime(firstMessageAt!),
    'last_message_at': lastMessageAt == null
        ? null
        : _formatToolDateTime(lastMessageAt!),
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
    required this.totalMessages,
    required this.chunks,
  });

  final int totalMessages;
  final List<AiConversationToolChunk> chunks;

  Map<String, dynamic> toJson() => {
    'total_messages': totalMessages,
    'total_chunks': chunks.length,
    'chunks': chunks.map((chunk) => chunk.toJson()).toList(growable: false),
  };
}

class AiConversationToolChunkPage {
  const AiConversationToolChunkPage({
    required this.offset,
    required this.totalMessages,
    required this.messages,
    required this.nextOffset,
  });

  final int offset;
  final int totalMessages;
  final List<AiConversationToolMessage> messages;
  final int? nextOffset;

  Map<String, dynamic> toJson() => {
    'offset': offset,
    'total_messages': totalMessages,
    'returned_count': messages.length,
    'next_offset': nextOffset,
    'messages': messages
        .map((message) => message.toJson())
        .toList(growable: false),
  };
}

class AiConversationToolSearchResult {
  const AiConversationToolSearchResult({
    required this.messages,
    required this.nextAnchorId,
  });

  final List<AiConversationToolMessage> messages;
  final String? nextAnchorId;

  Map<String, dynamic> toJson() => {
    'returned_count': messages.length,
    'next_anchor_id': nextAnchorId,
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
    String? anchorMessageId,
  });

  Future<AiImageOcrTextResult> readImageText({
    required String conversationId,
    required String messageId,
  });
}

class DatabaseAiConversationToolService implements AiConversationToolService {
  DatabaseAiConversationToolService(this.database);

  final Database database;
  late final AiImageOcrService _imageOcrService = AiImageOcrService(database);

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
      messageCount: messageCount,
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
      totalMessages: totalMessages,
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

    final toolMessages = <AiConversationToolMessage>[];
    for (final message in messages) {
      toolMessages.add(await _messageItemToToolMessage(message));
    }

    return AiConversationToolChunkPage(
      offset: safeOffset,
      totalMessages: totalMessages,
      messages: toolMessages,
      nextOffset: nextOffset,
    );
  }

  @override
  Future<AiConversationToolSearchResult> searchConversationMessages({
    required String conversationId,
    required String query,
    required int limit,
    String? anchorMessageId,
  }) async {
    final messages = await database.fuzzySearchMessage(
      query: query,
      limit: limit,
      conversationIds: [conversationId],
      anchorMessageId: anchorMessageId,
    );
    if (messages.isEmpty) {
      return const AiConversationToolSearchResult(
        messages: [],
        nextAnchorId: null,
      );
    }
    final fullMessages = await database.messageDao
        .messageItemByMessageIds(
          messages.map((message) => message.messageId).toList(),
        )
        .get();
    final fullMessageById = {
      for (final message in fullMessages) message.messageId: message,
    };
    final toolMessages = <AiConversationToolMessage>[];
    for (final message in messages) {
      final fullMessage = fullMessageById[message.messageId];
      toolMessages.add(
        fullMessage == null
            ? _searchMessageToToolMessage(message, query: query)
            : await _messageItemToToolMessage(
                fullMessage,
                query: query,
                maxLength: _kSearchMessageSnippetRadius * 2,
                includeContext: true,
                resolveMissingQuote: true,
              ),
      );
    }

    return AiConversationToolSearchResult(
      messages: toolMessages,
      nextAnchorId: messages.length < limit ? null : messages.last.messageId,
    );
  }

  @override
  Future<AiImageOcrTextResult> readImageText({
    required String conversationId,
    required String messageId,
  }) => _imageOcrService.recognizeMessageImageText(
    conversationId: conversationId,
    messageId: messageId,
  );

  Future<AiConversationToolMessage> _messageItemToToolMessage(
    MessageItem message, {
    String? query,
    int? maxLength,
    bool includeContext = false,
    bool resolveMissingQuote = false,
  }) async {
    final contextMessages = includeContext
        ? await _contextMessageMapsAround(message)
        : const <Map<String, dynamic>>[];
    final quotedByMessages = includeContext
        ? await _quotedByMessageMaps(message)
        : const <Map<String, dynamic>>[];
    return AiConversationToolMessage(
      messageId: message.messageId,
      createdAt: message.createdAt,
      senderName: message.userFullName ?? message.userId,
      type: message.type,
      text: _messageText(
        content: message.content,
        mediaName: message.mediaName,
        type: message.type,
        query: query,
        maxLength: maxLength ?? _kMaxConversationMessageTextLength,
      ),
      quotedMessage: await _quotedMessageMap(
        message,
        resolveMissing: resolveMissingQuote,
      ),
      contextMessages: contextMessages,
      quotedByMessages: quotedByMessages,
    );
  }

  AiConversationToolMessage _searchMessageToToolMessage(
    SearchMessageDetailItem message, {
    required String query,
  }) => AiConversationToolMessage(
    messageId: message.messageId,
    createdAt: message.createdAt,
    senderName: message.senderFullName ?? message.senderId,
    type: message.type,
    text: _messageText(
      content: message.content,
      mediaName: message.mediaName,
      type: message.type,
      query: query,
      maxLength: _kSearchMessageSnippetRadius * 2,
    ),
  );

  Future<List<Map<String, dynamic>>> _contextMessageMapsAround(
    MessageItem message,
  ) async {
    final orderInfo = await database.messageDao.messageOrderInfo(
      message.messageId,
    );
    if (orderInfo == null) {
      return const [];
    }

    final beforeMessages = await database.messageDao
        .beforeMessagesByConversationId(
          orderInfo,
          message.conversationId,
          _kSearchContextBeforeLimit,
        )
        .get();
    final afterMessages = await database.messageDao
        .afterMessagesByConversationId(
          orderInfo,
          message.conversationId,
          _kSearchContextAfterLimit,
        )
        .get();
    return [
      for (final item in beforeMessages.reversed) _messageItemToToolMap(item),
      for (final item in afterMessages) _messageItemToToolMap(item),
    ];
  }

  Future<List<Map<String, dynamic>>> _quotedByMessageMaps(
    MessageItem message,
  ) async {
    final messages = await database.messageDao
        .messagesByQuoteId(
          message.conversationId,
          message.messageId,
          _kSearchQuotedByLimit,
        )
        .get();
    return messages.map(_messageItemToToolMap).toList(growable: false);
  }

  Future<Map<String, dynamic>?> _quotedMessageMap(
    MessageItem message, {
    required bool resolveMissing,
  }) async {
    final quote = aiMessageQuotedItem(message);
    if (quote != null) {
      return _quoteMessageItemToToolMap(quote);
    }
    if (!resolveMissing) {
      return null;
    }
    final quoteId = message.quoteId?.trim();
    if (quoteId == null || quoteId.isEmpty) {
      return null;
    }
    final resolved = await database.messageDao.findMessageItemById(
      message.conversationId,
      quoteId,
    );
    if (resolved == null) {
      return {
        'message_id': quoteId,
        'unavailable': true,
      };
    }
    return _quoteMessageItemToToolMap(resolved);
  }

  Map<String, dynamic> _messageItemToToolMap(MessageItem message) => {
    'message_id': message.messageId,
    'created_at': _formatToolDateTime(message.createdAt),
    'sender_name': message.userFullName ?? message.userId,
    'type': message.type,
    'text': _messageText(
      content: message.content,
      mediaName: message.mediaName,
      type: message.type,
      maxLength: _kMaxConversationMessageTextLength,
    ),
  };

  Map<String, dynamic> _quoteMessageItemToToolMap(QuoteMessageItem message) => {
    'message_id': message.messageId,
    'created_at': _formatToolDateTime(message.createdAt),
    'sender_name': message.userFullName ?? message.userId,
    'type': message.type,
    'text': _truncateText(
      aiQuoteMessageContextText(message),
      _kMaxConversationMessageTextLength,
    ),
  };

  String _messageText({
    required String? content,
    required String? mediaName,
    required String type,
    String? query,
    int? maxLength,
  }) {
    if (content?.trim().isNotEmpty == true) {
      final text = content!.trim();
      final snippet = query == null ? text : _searchSnippet(text, query);
      return _truncateText(snippet, maxLength);
    }
    if (mediaName?.isNotEmpty == true) {
      return '[$type] $mediaName';
    }
    if (type.isImage) {
      return '[$type image; use read_image_text with message_id when the user '
          'asks about text in this image]';
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
          'Get message count and first/last timestamps for the conversation, '
          'optionally limited to a date range. Use this before date-scoped or '
          'unread summaries to understand coverage.',
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
          'List offsets for reading conversation messages in batches, '
          'optionally limited to a date range. Use this to plan exhaustive '
          'summaries or wide history review.',
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
          'Read conversation messages by offset and limit, optionally limited '
          'to a date range. Use this for unread summaries, date-scoped '
          'summaries, or surrounding context after a search hit. Messages may '
          'include quoted_message when they directly quote another message.',
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
          'Search messages in the current conversation by keyword, phrase, '
          'person, topic, link, or file name. Use anchor_id to page through '
          'more matches when needed. Results include nearby context messages '
          'and quote relationships when available.',
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
            anchorMessageId: input.anchorMessageId,
          );
          return result.toJson();
        },
      ),
    ),
    genkit.Tool<ReadImageTextInput, String>(
      name: 'read_image_text',
      description:
          'Run local OCR for an image message in the current conversation. '
          'Use this when the user asks what text appears in an image, '
          'screenshot, photo, receipt, document, or error capture. OCR only '
          'recognizes visible text and may be incomplete; do not treat it as '
          'full visual understanding.',
      inputSchema: ReadImageTextInput.schema,
      fn: (input, context) => _executeTool(
        conversationId: conversationId,
        name: 'read_image_text',
        arguments: input.toArguments(),
        context: context,
        onEvent: onEvent,
        fn: () async {
          final result = await service.readImageText(
            conversationId: conversationId,
            messageId: input.messageId,
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
      final encodedResult = encodeAiToolResult(result);
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
      return encodeAiToolResult({'error': '$error'});
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
    'start': startInclusive?.toIso8601String(),
    'end': endExclusive?.toIso8601String(),
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
        'size': {
          'type': 'integer',
          'description': 'Batch size, 1-200.',
        },
      },
    ),
    parse: (value) {
      final arguments = _jsonMap(value);
      final (startInclusive, endExclusive) = _parseRange(arguments);
      return ListConversationChunksInput(
        chunkSize: _parseInt(
          arguments,
          'size',
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
    'size': chunkSize,
    'start': startInclusive?.toIso8601String(),
    'end': endExclusive?.toIso8601String(),
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
          'description': 'Zero-based message offset.',
        },
        'limit': {
          'type': 'integer',
          'description': 'Message count, 1-200.',
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
    'start': startInclusive?.toIso8601String(),
    'end': endExclusive?.toIso8601String(),
  }..removeWhere((_, value) => value == null);
}

class SearchConversationMessagesInput {
  const SearchConversationMessagesInput({
    required this.query,
    required this.limit,
    this.anchorMessageId,
  });

  final String query;
  final int limit;
  final String? anchorMessageId;

  static final schema = SchemanticType.from<SearchConversationMessagesInput>(
    jsonSchema: {
      'type': 'object',
      'properties': {
        'query': {
          'type': 'string',
          'description': 'Search text.',
        },
        'limit': {
          'type': 'integer',
          'description': 'Max matches, 1-20.',
        },
        'anchor_id': {
          'type': 'string',
          'description': 'Use next_anchor_id from the previous page.',
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
        anchorMessageId: _parseOptionalString(arguments, 'anchor_id'),
      );
    },
  );

  Map<String, dynamic> toArguments() => {
    'query': query,
    'limit': limit,
    'anchor_id': anchorMessageId,
  }..removeWhere((_, value) => value == null);
}

class ReadImageTextInput {
  const ReadImageTextInput({required this.messageId});

  final String messageId;

  static final schema = SchemanticType.from<ReadImageTextInput>(
    jsonSchema: {
      'type': 'object',
      'properties': {
        'message_id': {
          'type': 'string',
          'description': 'Image message id in the current conversation.',
        },
      },
      'required': ['message_id'],
      'additionalProperties': false,
    },
    parse: (value) {
      final arguments = _jsonMap(value);
      return ReadImageTextInput(
        messageId: _parseRequiredString(arguments, 'message_id'),
      );
    },
  );

  Map<String, dynamic> toArguments() => {'message_id': messageId};
}

Map<String, Object?> _rangeSchema({
  Map<String, Object?> properties = const {},
  List<String> required = const [],
}) => {
  'type': 'object',
  'properties': {
    'start': {
      'type': 'string',
      'description': 'Inclusive ISO-8601 start.',
    },
    'end': {
      'type': 'string',
      'description': 'Exclusive ISO-8601 end.',
    },
    ...properties,
  },
  if (required.isNotEmpty) 'required': required,
  'additionalProperties': false,
};

(DateTime?, DateTime?) _parseRange(Map<String, dynamic> arguments) {
  final startInclusive = _parseDateTime(arguments, 'start');
  final endExclusive = _parseDateTime(arguments, 'end');
  if (startInclusive != null &&
      endExclusive != null &&
      !endExclusive.isAfter(startInclusive)) {
    throw const FormatException('end must be later than start');
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

String? _parseOptionalString(Map<String, dynamic> arguments, String key) {
  final raw = arguments[key];
  if (raw == null) {
    return null;
  }
  if (raw is! String) {
    throw FormatException('$key must be a string');
  }
  final value = raw.trim();
  return value.isEmpty ? null : value;
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

String _formatToolDateTime(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}T'
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}'
    '${value.isUtc ? 'Z' : ''}';

String _searchSnippet(String text, String query) {
  final trimmedQuery = query.trim();
  if (trimmedQuery.isEmpty || text.length <= _kSearchMessageSnippetRadius * 2) {
    return text;
  }

  final lowerText = text.toLowerCase();
  final lowerQuery = trimmedQuery.toLowerCase();
  final index = lowerText.indexOf(lowerQuery);
  if (index < 0) {
    return _truncateText(text, _kSearchMessageSnippetRadius * 2);
  }

  final start = math.max(0, index - _kSearchMessageSnippetRadius);
  final end = math.min(
    text.length,
    index + trimmedQuery.length + _kSearchMessageSnippetRadius,
  );
  final prefix = start == 0 ? '' : '...';
  final suffix = end == text.length ? '' : '...';
  return '$prefix${text.substring(start, end)}$suffix';
}

String _truncateText(String text, int? maxLength) {
  if (maxLength == null || text.length <= maxLength) {
    return text;
  }
  const suffix = '... [truncated]';
  final end = math.max(0, maxLength - suffix.length);
  return '${text.substring(0, end)}$suffix';
}

String encodeAiToolResult(Map<String, dynamic> result) =>
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
