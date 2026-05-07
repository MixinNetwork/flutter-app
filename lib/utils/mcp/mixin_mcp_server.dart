import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:genkit/genkit.dart' as genkit;
import 'package:mcp_server/mcp_server.dart' as mcp;
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    show CircleConversationAction, CircleConversationRequest;
import 'package:schemantic/schemantic.dart';

import '../../ai/model/ai_chat_metadata.dart';
import '../../ai/tools/ai_conversation_tool_service.dart';
import '../../db/ai_database.dart';
import '../../db/dao/circle_dao.dart';
import '../../db/dao/conversation_dao.dart';
import '../../db/dao/message_dao.dart';
import '../../db/dao/participant_dao.dart';
import '../../db/database.dart';
import '../../db/mixin_database.dart';
import '../../enum/message_category.dart';
import '../extension/extension.dart';
import '../logger.dart';
import '../system/package_info.dart';
import 'mixin_mcp_bridge.dart';

typedef CurrentConversationIdResolver = String? Function();

class MixinMcpToolInfo {
  const MixinMcpToolInfo({
    required this.name,
    required this.description,
    required this.scopeKey,
    required this.scopeTitle,
    required this.enabled,
    required this.requiredArguments,
  });

  final String name;
  final String description;
  final String scopeKey;
  final String scopeTitle;
  final bool enabled;
  final List<String> requiredArguments;
}

enum _McpPermissionScope {
  read,
  appControl,
  draftWrite,
  circleManagement,
}

extension on _McpPermissionScope {
  String get key => switch (this) {
    _McpPermissionScope.read => 'read',
    _McpPermissionScope.appControl => 'app_control',
    _McpPermissionScope.draftWrite => 'draft_write',
    _McpPermissionScope.circleManagement => 'circle_management',
  };

  String get title => switch (this) {
    _McpPermissionScope.read => 'Read',
    _McpPermissionScope.appControl => 'App Control',
    _McpPermissionScope.draftWrite => 'Draft Editing',
    _McpPermissionScope.circleManagement => 'Circle Management',
  };
}

class MixinMcpServer extends ChangeNotifier {
  MixinMcpServer._();

  static final MixinMcpServer instance = MixinMcpServer._();
  static const int defaultPort = 55001;

  mcp.Server? _server;
  mcp.ServerTransport? _transport;
  Database? _database;
  String? _userId;
  CurrentConversationIdResolver? _currentConversationId;
  late AiConversationToolService _conversationTools;
  List<genkit.Tool<Map<String, dynamic>, Map<String, dynamic>>> _tools =
      const [];
  Object? _lastStartError;

  Uri? get endpoint {
    if (_server == null) return null;
    return Uri(
      scheme: 'http',
      host: InternetAddress.loopbackIPv4.address,
      port: defaultPort,
      path: '/mcp',
    );
  }

  bool get isRunning => _server != null && _transport != null;

  Object? get lastStartError => _lastStartError;

  static List<MixinMcpToolInfo> toolInfos(Database database) => _toolSpecs
      .map(
        (spec) => MixinMcpToolInfo(
          name: spec.name,
          description: spec.description,
          scopeKey: spec.scope.key,
          scopeTitle: spec.scope.title,
          enabled: _toolEnabled(database, spec),
          requiredArguments: spec.required,
        ),
      )
      .toList(growable: false);

  Future<void> start({
    required Database database,
    required String userId,
    required CurrentConversationIdResolver currentConversationId,
  }) async {
    if (_server != null &&
        identical(_database, database) &&
        _userId == userId) {
      return;
    }
    await stop();
    _database = database;
    _userId = userId;
    _currentConversationId = currentConversationId;
    _conversationTools = DatabaseAiConversationToolService(database);
    _tools = _createGenkitTools();
    final token = database.settingProperties.mcpServerToken;
    if (token == null || token.isEmpty) {
      throw StateError('MCP access token is unavailable');
    }
    _lastStartError = null;
    try {
      final transport = mcp.StreamableHttpServerTransport(
        config: mcp.StreamableHttpServerConfig(
          host: InternetAddress.loopbackIPv4.address,
          port: defaultPort,
          fallbackPorts: const [],
          authToken: token,
          isJsonResponseEnabled: true,
          enableGetStream: false,
        ),
      );
      await transport.start();
      final server = mcp.Server(
        name: 'mixin-local',
        version: '0.1.0',
        capabilities: mcp.ServerCapabilities.simple(tools: true),
      );
      for (final tool in _tools) {
        _registerMcpTool(server, tool);
      }
      server.connect(transport);
      _server = server;
      _transport = transport;
      i('Mixin MCP server listening at $endpoint');
      notifyListeners();
    } catch (error, stacktrace) {
      _lastStartError = error;
      notifyListeners();
      e(
        'Failed to start Mixin MCP server on '
        '${InternetAddress.loopbackIPv4.address}:$defaultPort: '
        '$error',
        stacktrace,
      );
      rethrow;
    }
  }

  Future<void> stop() async {
    final server = _server;
    final transport = _transport;
    _server = null;
    _transport = null;
    _database = null;
    _userId = null;
    _currentConversationId = null;
    _tools = const [];
    if (server != null) {
      server
        ..disconnect()
        ..dispose();
      transport?.close();
      i('Mixin MCP server stopped');
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _callTool(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    final database = _requireDatabase();
    _ensureToolEnabled(database, name);
    switch (name) {
      case 'mixin_get_app_status':
        final info = await getPackageInfo();
        final conversationId = _currentConversationId?.call();
        return {
          'logged_in': _userId != null,
          'user_id': _userId,
          'identity_number': database.identityNumber,
          'active_conversation_id': conversationId,
          'active_input_conversation_id':
              MixinMcpBridge.instance.activeInputConversationId,
          'app': {
            'name': info.appName,
            'version': info.version,
            'build_number': info.buildNumber,
          },
          'permission_scopes': _permissionScopes(database),
          'capabilities': _tools
              .map((tool) => tool.name)
              .toList(growable: false),
          'enabled_capabilities': _toolSpecs
              .where((spec) => _toolEnabled(database, spec))
              .map((spec) => spec.name)
              .toList(growable: false),
        };
      case 'mixin_list_conversations':
        final circleId = _optionalString(arguments, 'circle_id');
        final page = await _readConversationPage(database, arguments);
        return {
          'circle_id': circleId,
          'conversations': page.conversations
              .map(_conversationToJson)
              .toList(growable: false),
          'pagination': page.toJson(),
        }..removeWhere((_, value) => value == null);
      case 'mixin_get_conversation':
        final conversation = await _conversationById(
          database,
          _requiredString(arguments, 'conversation_id'),
        );
        return {'conversation': _conversationToJson(conversation)};
      case 'mixin_resolve_conversation':
        return {
          'conversation': _conversationToJson(
            await _resolveConversation(database, arguments),
          ),
        };
      case 'mixin_get_conversation_stats':
        final stats = await _conversationTools.getConversationStats(
          conversationId: _requiredString(arguments, 'conversation_id'),
          startInclusive: _date(arguments, 'start'),
          endExclusive: _date(arguments, 'end'),
        );
        return stats.toJson();
      case 'mixin_list_messages':
        return _listMessages(database, arguments);
      case 'mixin_get_message':
        final message = await _messageById(
          database,
          _requiredString(arguments, 'message_id'),
        );
        return {'message': _messageToJson(message, includePinState: true)};
      case 'mixin_get_message_context':
        final message = await _messageById(
          database,
          _requiredString(arguments, 'message_id'),
        );
        final limit = _int(
          arguments,
          'limit',
          defaultValue: 10,
          min: 1,
          max: 50,
        );
        final info = await database.messageDao.messageOrderInfo(
          message.messageId,
        );
        if (info == null) throw StateError('Message order info not found');
        final before = await database.messageDao
            .beforeMessagesByConversationId(info, message.conversationId, limit)
            .get();
        final after = await database.messageDao
            .afterMessagesByConversationId(info, message.conversationId, limit)
            .get();
        return {
          'before': _messagesToJson(before.reversed, includePinState: true),
          'message': _messageToJson(message, includePinState: true),
          'after': _messagesToJson(after, includePinState: true),
        };
      case 'mixin_read_image_message_text':
        final result = await _conversationTools.readImageText(
          conversationId: _requiredString(arguments, 'conversation_id'),
          messageId: _requiredString(arguments, 'message_id'),
        );
        return result.toJson();
      case 'mixin_list_conversation_participants':
        final query = _optionalString(arguments, 'query');
        final limit = _int(
          arguments,
          'limit',
          defaultValue: 50,
          min: 1,
          max: 200,
        );
        final participants = await database.participantDao
            .groupParticipantsByConversationId(
              _requiredString(arguments, 'conversation_id'),
            )
            .get();
        final filtered = query == null
            ? participants
            : participants
                  .where(
                    (participant) => _participantMatches(participant, query),
                  )
                  .toList(growable: false);
        final page = _participantPageFromRows(
          filtered,
          limit: limit,
          cursorUserId: _optionalString(arguments, 'cursor_user_id'),
        );
        return {
          'participants': page.participants
              .map(_participantToJson)
              .toList(growable: false),
          'pagination': page.toJson(),
        };
      case 'mixin_resolve_conversation_participant':
        final query = _requiredString(arguments, 'query');
        final participants = await database.participantDao
            .groupParticipantsByConversationId(
              _requiredString(arguments, 'conversation_id'),
            )
            .get();
        return {
          'participants': participants
              .where((participant) => _participantMatches(participant, query))
              .take(_int(arguments, 'limit', defaultValue: 5, min: 1, max: 20))
              .map(_participantToJson)
              .toList(growable: false),
        };
      case 'mixin_list_circles':
        final circles = await database.circleDao.allCircles().get();
        return {
          'circles': circles.map(_circleToJson).toList(growable: false),
        };
      case 'mixin_open_conversation':
        final conversationId = _requiredString(arguments, 'conversation_id');
        await MixinMcpBridge.instance.openConversation(conversationId);
        return {'opened': true, 'conversation_id': conversationId};
      case 'mixin_reveal_message':
        final message = await _messageById(
          database,
          _requiredString(arguments, 'message_id'),
        );
        await MixinMcpBridge.instance.revealMessage(
          conversationId: message.conversationId,
          messageId: message.messageId,
        );
        return {
          'revealed': true,
          'conversation_id': message.conversationId,
          'message_id': message.messageId,
        };
      case 'mixin_get_conversation_draft':
        final conversationId = _requiredString(arguments, 'conversation_id');
        return {
          'conversation_id': conversationId,
          'draft': await MixinMcpBridge.instance.getDraft(
            database,
            conversationId,
          ),
        };
      case 'mixin_set_conversation_draft':
        final conversationId = _requiredString(arguments, 'conversation_id');
        await MixinMcpBridge.instance.setDraft(
          database,
          conversationId,
          _requiredString(arguments, 'text'),
        );
        return {'updated': true, 'conversation_id': conversationId};
      case 'mixin_insert_conversation_text':
        final conversationId = _requiredString(arguments, 'conversation_id');
        await MixinMcpBridge.instance.insertText(
          database,
          conversationId,
          _requiredString(arguments, 'text'),
        );
        return {'updated': true, 'conversation_id': conversationId};
      case 'mixin_clear_conversation_draft':
        final conversationId = _requiredString(arguments, 'conversation_id');
        await MixinMcpBridge.instance.setDraft(database, conversationId, '');
        return {'updated': true, 'conversation_id': conversationId};
      case 'mixin_create_circle':
        final name = _requiredString(arguments, 'name');
        final conversationIds = _optionalStringList(
          arguments,
          'conversation_ids',
        );
        await MixinMcpBridge.instance.createCircle(
          name: name,
          conversations: await _circleConversationRequests(
            database,
            conversationIds,
            CircleConversationAction.add,
          ),
        );
        return {
          'created': true,
          'name': name,
          'conversation_ids': conversationIds,
        };
      case 'mixin_rename_circle':
        final circleId = _requiredString(arguments, 'circle_id');
        final name = _requiredString(arguments, 'name');
        await MixinMcpBridge.instance.renameCircle(
          circleId: circleId,
          name: name,
        );
        return {'updated': true, 'circle_id': circleId, 'name': name};
      case 'mixin_delete_circle':
        final circleId = _requiredString(arguments, 'circle_id');
        await MixinMcpBridge.instance.deleteCircle(circleId);
        return {'deleted': true, 'circle_id': circleId};
      case 'mixin_add_conversations_to_circle':
        final circleId = _requiredString(arguments, 'circle_id');
        final conversationIds = _requiredStringList(
          arguments,
          'conversation_ids',
        );
        await MixinMcpBridge.instance.addConversationsToCircle(
          circleId: circleId,
          conversations: await _circleConversationRequests(
            database,
            conversationIds,
            CircleConversationAction.add,
          ),
        );
        return {
          'updated': true,
          'circle_id': circleId,
          'conversation_ids': conversationIds,
        };
      case 'mixin_remove_conversations_from_circle':
        final circleId = _requiredString(arguments, 'circle_id');
        final conversationIds = _requiredStringList(
          arguments,
          'conversation_ids',
        );
        await MixinMcpBridge.instance.removeConversationsFromCircle(
          circleId: circleId,
          conversationIds: conversationIds,
        );
        return {
          'updated': true,
          'circle_id': circleId,
          'conversation_ids': conversationIds,
        };
      case 'mixin_attach_message_to_ai_context':
        final message = await _messageById(
          database,
          _requiredString(arguments, 'message_id'),
        );
        await MixinMcpBridge.instance.attachMessage(
          conversationId: message.conversationId,
          message: message,
        );
        return {
          'attached': true,
          'conversation_id': message.conversationId,
          'message_id': message.messageId,
        };
      case 'mixin_list_conversation_ai_threads':
        final threads = await database.aiChatMessageDao
            .watchThreads(_requiredString(arguments, 'conversation_id'))
            .first;
        return {
          'threads': threads.map(_aiThreadToJson).toList(growable: false),
        };
      case 'mixin_read_ai_thread':
        final threadId = _requiredString(arguments, 'thread_id');
        final thread = await database.aiChatMessageDao.threadById(threadId);
        if (thread == null) throw StateError('AI thread not found');
        final messages = await database.aiChatMessageDao.threadMessages(
          threadId,
        );
        return {
          'thread': _aiThreadToJson(thread),
          'messages': messages.map(_aiMessageToJson).toList(growable: false),
        };
      case 'mixin_get_ai_message_tool_events':
        final messageId = _requiredString(arguments, 'message_id');
        final message = await database.aiChatMessageDao.messageById(messageId);
        if (message == null) throw StateError('AI message not found');
        return {
          'message_id': message.id,
          'tool_events': aiMetadataToolEvents(message.metadata),
        };
      default:
        throw StateError('Unknown tool: $name');
    }
  }

  List<genkit.Tool<Map<String, dynamic>, Map<String, dynamic>>>
  _createGenkitTools() => _toolSpecs
      .map(
        (spec) => genkit.Tool<Map<String, dynamic>, Map<String, dynamic>>(
          name: spec.name,
          description: spec.description,
          inputSchema: SchemanticType.from<Map<String, dynamic>>(
            jsonSchema: spec.inputSchema,
            parse: _jsonMap,
          ),
          fn: (input, _) => _callTool(spec.name, input),
        ),
      )
      .toList(growable: false);

  void _registerMcpTool(
    mcp.Server server,
    genkit.Tool<Map<String, dynamic>, Map<String, dynamic>> tool,
  ) {
    server.addTool(
      name: tool.name,
      description: tool.description ?? '',
      inputSchema: Map<String, dynamic>.from(
        tool.inputSchema?.jsonSchema() ?? _emptyObjectSchema,
      ),
      handler: (arguments) async {
        final startedAt = DateTime.now();
        i('MCP tool call ${tool.name}: ${_auditArguments(arguments)}');
        Map<String, dynamic> data;
        try {
          final result = await tool.runRaw(arguments);
          data = _toolResult(tool.name, result.result, startedAt);
          i(
            'MCP tool result ${tool.name}: ok '
            '${data['elapsed_ms']}ms',
          );
        } catch (error, stacktrace) {
          data = _toolErrorResult(tool.name, error, startedAt);
          e('MCP tool error ${tool.name}: $error', stacktrace);
        }
        return mcp.CallToolResult(
          content: [mcp.TextContent(text: encodeAiToolResult(data))],
          structuredContent: data,
        );
      },
    );
  }

  Database _requireDatabase() {
    final database = _database;
    if (database == null) throw StateError('Database is unavailable');
    return database;
  }
}

void _ensureToolEnabled(Database database, String name) {
  for (final spec in _toolSpecs) {
    if (spec.name != name) continue;
    if (_toolEnabled(database, spec)) return;
    throw StateError('MCP permission scope "${spec.scope.key}" is disabled');
  }
}

Map<String, bool> _permissionScopes(Database database) => {
  _McpPermissionScope.read.key: true,
  _McpPermissionScope.appControl.key: true,
  _McpPermissionScope.draftWrite.key:
      database.settingProperties.enableMcpDraftTools,
  _McpPermissionScope.circleManagement.key:
      database.settingProperties.enableMcpCircleManagement,
  'account_write': false,
  'message_send': false,
};

bool _toolEnabled(Database database, _Tool spec) {
  switch (spec.scope) {
    case _McpPermissionScope.read:
    case _McpPermissionScope.appControl:
      return true;
    case _McpPermissionScope.draftWrite:
      return database.settingProperties.enableMcpDraftTools;
    case _McpPermissionScope.circleManagement:
      return database.settingProperties.enableMcpCircleManagement;
  }
}

Map<String, dynamic> _toolResult(
  String name,
  Map<String, dynamic> result,
  DateTime startedAt,
) => {
  'ok': true,
  'tool': name,
  ...result,
  'elapsed_ms': DateTime.now().difference(startedAt).inMilliseconds,
};

Map<String, dynamic> _toolErrorResult(
  String name,
  Object error,
  DateTime startedAt,
) => {
  'ok': false,
  'tool': name,
  'error': {
    'type': error.runtimeType.toString(),
    'message': error.toString(),
  },
  'elapsed_ms': DateTime.now().difference(startedAt).inMilliseconds,
};

String _auditArguments(Map<String, dynamic> arguments) =>
    const JsonEncoder().convert(_redactForAudit(arguments));

Object? _redactForAudit(Object? value, [String? key]) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key.toString(): _redactForAudit(
          entry.value,
          entry.key.toString(),
        ),
    };
  }
  if (value is Iterable) {
    return value.map(_redactForAudit).toList(growable: false);
  }
  final normalizedKey = key?.toLowerCase();
  if (value is String &&
      normalizedKey != null &&
      (normalizedKey.contains('token') ||
          normalizedKey.contains('secret') ||
          normalizedKey == 'text' ||
          normalizedKey == 'content' ||
          normalizedKey == 'draft')) {
    return '<${value.length} chars>';
  }
  return value;
}

const _messagePageLatest = 'latest';
const _messagePageBefore = 'before';
const _messagePageAfter = 'after';
const _messageKindAll = 'all';
const _messageKindAttachments = 'attachments';
const _messageKindPinned = 'pinned';
const _messageKindMentions = 'mentions';
const _messageKindLinks = 'links';
const _conversationScanLimit = 5000;
const _attachmentMessageCategories = [
  MessageCategory.signalImage,
  MessageCategory.signalVideo,
  MessageCategory.signalData,
  MessageCategory.signalAudio,
  MessageCategory.plainImage,
  MessageCategory.plainVideo,
  MessageCategory.plainData,
  MessageCategory.plainAudio,
  MessageCategory.encryptedImage,
  MessageCategory.encryptedVideo,
  MessageCategory.encryptedData,
  MessageCategory.encryptedAudio,
];

class _ConversationPage {
  const _ConversationPage({
    required this.conversations,
    required this.limit,
    required this.hasMore,
    required this.order,
    this.cursorConversationId,
  });

  final List<ConversationItem> conversations;
  final int limit;
  final bool hasMore;
  final String order;
  final String? cursorConversationId;

  Map<String, dynamic> toJson() => {
    'order': order,
    'limit': limit,
    'cursor_conversation_id': cursorConversationId,
    'next_cursor_conversation_id': hasMore
        ? conversations.lastOrNull?.conversationId
        : null,
    'has_more': hasMore,
  }..removeWhere((_, value) => value == null);
}

class _ParticipantPage {
  const _ParticipantPage({
    required this.participants,
    required this.limit,
    required this.hasMore,
    this.cursorUserId,
  });

  final List<ParticipantUser> participants;
  final int limit;
  final bool hasMore;
  final String? cursorUserId;

  Map<String, dynamic> toJson() => {
    'order': 'full_name_identity_number_user_id',
    'limit': limit,
    'cursor_user_id': cursorUserId,
    'next_cursor_user_id': hasMore ? participants.lastOrNull?.userId : null,
    'has_more': hasMore,
  }..removeWhere((_, value) => value == null);
}

class _MessagePage {
  const _MessagePage({
    required this.messages,
    required this.page,
    required this.limit,
    required this.hasMore,
    this.cursorMessageId,
  });

  final List<MessageItem> messages;
  final String page;
  final int limit;
  final bool hasMore;
  final String? cursorMessageId;

  Map<String, dynamic> toJson() => _cursorPaginationToJson(
    page: page,
    limit: limit,
    hasMore: hasMore,
    cursorMessageId: cursorMessageId,
    oldestMessageId: messages.firstOrNull?.messageId,
    newestMessageId: messages.lastOrNull?.messageId,
  );
}

class _PinnedMessagePage {
  const _PinnedMessagePage({
    required this.pins,
    required this.page,
    required this.limit,
    required this.hasMore,
    this.cursorMessageId,
  });

  final List<PinMessage> pins;
  final String page;
  final int limit;
  final bool hasMore;
  final String? cursorMessageId;

  Map<String, dynamic> toJson() => {
    ..._cursorPaginationToJson(
      page: page,
      limit: limit,
      hasMore: hasMore,
      cursorMessageId: cursorMessageId,
      oldestMessageId: pins.firstOrNull?.messageId,
      newestMessageId: pins.lastOrNull?.messageId,
    ),
    'order': 'oldest_to_newest_by_pinned_at',
  };
}

Future<Map<String, dynamic>> _listMessages(
  Database database,
  Map<String, dynamic> arguments,
) async {
  final query = _optionalString(arguments, 'query');
  return query == null
      ? _listConversationMessages(database, arguments)
      : _searchMessages(database, arguments, query);
}

Future<Map<String, dynamic>> _listConversationMessages(
  Database database,
  Map<String, dynamic> arguments,
) async {
  final conversationId = _requiredString(arguments, 'conversation_id');
  final kind = _messageKind(arguments);
  if (_optionalString(arguments, 'circle_id') != null) {
    throw ArgumentError('circle_id only applies when query is set');
  }
  return switch (kind) {
    _messageKindAll => () async {
      final page = await _readMessagePage(database, arguments);
      return {
        'messages': _messagesToJson(
          page.messages,
          includePinState: _bool(arguments, 'include_pin_state'),
        ),
        'pagination': page.toJson(),
      };
    }(),
    _messageKindAttachments => () async {
      final page = await _readMessagePage(
        database,
        arguments,
        attachmentMessagesOnly: true,
      );
      return {
        'messages': _messagesToJson(page.messages, includePinState: true),
        'pagination': page.toJson(),
      };
    }(),
    _messageKindPinned => () async {
      final page = await _readPinnedMessagePage(
        database,
        conversationId: conversationId,
        arguments: arguments,
      );
      return {
        'messages': await _pinnedMessagesToJson(database, page.pins),
        'pagination': page.toJson(),
      };
    }(),
    _messageKindMentions => () async {
      final page = await _readMentionMessagePage(database, arguments);
      return {
        'messages': _messagesToJson(page.messages, includePinState: true),
        'pagination': page.toJson(),
      };
    }(),
    _messageKindLinks => () async {
      final page = await _readLinkMessagePage(database, arguments);
      return {
        'messages': _messagesToJson(page.messages, includePinState: true),
        'pagination': page.toJson(),
      };
    }(),
    _ => throw ArgumentError('Unsupported message kind: $kind'),
  };
}

Future<Map<String, dynamic>> _searchMessages(
  Database database,
  Map<String, dynamic> arguments,
  String query,
) async {
  final kind = _messageKind(arguments);
  if (kind != _messageKindAll && kind != _messageKindAttachments) {
    throw ArgumentError(
      'kind is only supported as all or attachments when query is set',
    );
  }
  final conversationId = _optionalString(arguments, 'conversation_id');
  final circleId = _optionalString(arguments, 'circle_id');
  final conversationIds = conversationId == null
      ? circleId == null
            ? const <String>[]
            : await database.conversationDao.conversationIdsByCircleId(circleId)
      : [conversationId];
  if (circleId != null && conversationIds.isEmpty) {
    return {
      'messages': const <Map<String, dynamic>>[],
      'pagination': {
        'limit': _searchMessageLimit(arguments),
        'has_more': false,
      },
    };
  }
  final limit = _searchMessageLimit(arguments);
  final messages = await database.fuzzySearchMessage(
    query: query,
    limit: limit + 1,
    conversationIds: conversationIds,
    userId: _optionalString(arguments, 'sender_id'),
    categories: _searchMessageCategories(arguments, kind),
    anchorMessageId: _optionalString(arguments, 'cursor_message_id'),
  );
  final hasMore = messages.length > limit;
  final selected = messages.take(limit).toList(growable: false);
  return {
    'messages': _searchMessagesToJson(selected),
    'pagination': {
      'limit': limit,
      'cursor_message_id': _optionalString(arguments, 'cursor_message_id'),
      'next_cursor_message_id': hasMore ? selected.lastOrNull?.messageId : null,
      'has_more': hasMore,
    }..removeWhere((_, value) => value == null),
  };
}

Future<List<Map<String, dynamic>>> _pinnedMessagesToJson(
  Database database,
  List<PinMessage> pins,
) async {
  final messageIds = pins.map((pin) => pin.messageId).toList();
  final messages = await database.messageDao
      .messageItemByMessageIds(messageIds)
      .get();
  final messagesById = {
    for (final message in messages) message.messageId: message,
  };
  return pins
      .map((pin) {
        final message = messagesById[pin.messageId];
        if (message == null) return null;
        return {
          ..._messageToJson(message, includePinState: true),
          'pinned_at': _dateTime(pin.createdAt),
        };
      })
      .nonNulls
      .toList(growable: false);
}

int _searchMessageLimit(Map<String, dynamic> arguments) =>
    _int(arguments, 'limit', defaultValue: 100, min: 1, max: 200);

List<String> _searchMessageCategories(
  Map<String, dynamic> arguments,
  String kind,
) {
  final explicit = _optionalStringList(arguments, 'message_types');
  if (explicit.isNotEmpty) return explicit;
  return kind == _messageKindAttachments
      ? _attachmentMessageCategories
      : const [];
}

String _messageKind(Map<String, dynamic> arguments) {
  final kind = _optionalString(arguments, 'kind') ?? _messageKindAll;
  return switch (kind) {
    _messageKindAll ||
    _messageKindAttachments ||
    _messageKindPinned ||
    _messageKindMentions ||
    _messageKindLinks => kind,
    _ => throw ArgumentError(
      'kind must be one of all, attachments, pinned, mentions, or links',
    ),
  };
}

Future<_MessagePage> _readMessagePage(
  Database database,
  Map<String, dynamic> arguments, {
  bool attachmentMessagesOnly = false,
}) async {
  final conversationId = _requiredString(arguments, 'conversation_id');
  final limit = _int(arguments, 'limit', defaultValue: 100, min: 1, max: 200);
  final page = _messagePage(arguments);
  final cursorMessageId = _cursorMessageId(arguments, page);
  final before = page == _messagePageBefore
      ? await _messageOrderInfoForCursor(
          database,
          conversationId,
          cursorMessageId,
        )
      : null;
  final after = page == _messagePageAfter
      ? await _messageOrderInfoForCursor(
          database,
          conversationId,
          cursorMessageId,
        )
      : null;
  final ascending = page == _messagePageAfter;
  final rows = attachmentMessagesOnly
      ? await database.messageDao
            .attachmentMessagesByConversationId(
              conversationId,
              limit: limit + 1,
              startInclusive: _date(arguments, 'start'),
              endExclusive: _date(arguments, 'end'),
              before: before,
              after: after,
              senderId: _optionalString(arguments, 'sender_id'),
              senderIdentityNumber: _optionalString(
                arguments,
                'sender_identity_number',
              ),
              categories: _optionalStringList(arguments, 'message_types'),
              ascending: ascending,
            )
            .get()
      : await database.messageDao
            .messagesByConversationIdAndCreatedAtRange(
              conversationId,
              limit: limit + 1,
              startInclusive: _date(arguments, 'start'),
              endExclusive: _date(arguments, 'end'),
              before: before,
              after: after,
              senderId: _optionalString(arguments, 'sender_id'),
              senderIdentityNumber: _optionalString(
                arguments,
                'sender_identity_number',
              ),
              categories: _optionalStringList(arguments, 'message_types'),
              ascending: ascending,
            )
            .get();
  return _messagePageFromRows(
    rows,
    page: page,
    limit: limit,
    cursorMessageId: cursorMessageId,
    ascending: ascending,
  );
}

Future<_MessagePage> _readMentionMessagePage(
  Database database,
  Map<String, dynamic> arguments,
) async {
  final conversationId = _requiredString(arguments, 'conversation_id');
  final limit = _int(arguments, 'limit', defaultValue: 100, min: 1, max: 200);
  final page = _messagePage(arguments);
  final cursorMessageId = _cursorMessageId(arguments, page);
  final before = page == _messagePageBefore
      ? await _messageOrderInfoForCursor(
          database,
          conversationId,
          cursorMessageId,
        )
      : null;
  final after = page == _messagePageAfter
      ? await _messageOrderInfoForCursor(
          database,
          conversationId,
          cursorMessageId,
        )
      : null;
  final ascending = page == _messagePageAfter;
  final rows = await database.messageDao
      .mentionMessagesByConversationId(
        conversationId,
        limit: limit + 1,
        unreadOnly: _bool(arguments, 'unread_only'),
        before: before,
        after: after,
        ascending: ascending,
      )
      .get();
  return _messagePageFromRows(
    rows,
    page: page,
    limit: limit,
    cursorMessageId: cursorMessageId,
    ascending: ascending,
  );
}

Future<_MessagePage> _readLinkMessagePage(
  Database database,
  Map<String, dynamic> arguments,
) async {
  final conversationId = _requiredString(arguments, 'conversation_id');
  final limit = _int(arguments, 'limit', defaultValue: 100, min: 1, max: 200);
  final page = _messagePage(arguments);
  final cursorMessageId = _cursorMessageId(arguments, page);
  final before = page == _messagePageBefore
      ? await _messageOrderInfoForCursor(
          database,
          conversationId,
          cursorMessageId,
        )
      : null;
  final after = page == _messagePageAfter
      ? await _messageOrderInfoForCursor(
          database,
          conversationId,
          cursorMessageId,
        )
      : null;
  final ascending = page == _messagePageAfter;
  final rows = await database.messageDao
      .linkMessagesByConversationId(
        conversationId,
        limit: limit + 1,
        before: before,
        after: after,
        ascending: ascending,
      )
      .get();
  return _messagePageFromRows(
    rows,
    page: page,
    limit: limit,
    cursorMessageId: cursorMessageId,
    ascending: ascending,
  );
}

Future<_PinnedMessagePage> _readPinnedMessagePage(
  Database database, {
  required String conversationId,
  required Map<String, dynamic> arguments,
}) async {
  final limit = _int(arguments, 'limit', defaultValue: 100, min: 1, max: 200);
  final page = _messagePage(arguments);
  final cursorMessageId = _cursorMessageId(arguments, page);
  final pins = await database.pinMessageDao.pinMessagesByConversationId(
    conversationId: conversationId,
    limit: limit + 1,
    beforeMessageId: page == _messagePageBefore ? cursorMessageId : null,
    afterMessageId: page == _messagePageAfter ? cursorMessageId : null,
    ascending: page == _messagePageAfter,
  );
  final hasMore = pins.length > limit;
  final selected = pins.take(limit).toList(growable: false);
  return _PinnedMessagePage(
    pins: page == _messagePageAfter
        ? selected
        : selected.reversed.toList(growable: false),
    page: page,
    limit: limit,
    hasMore: hasMore,
    cursorMessageId: cursorMessageId,
  );
}

_MessagePage _messagePageFromRows(
  List<MessageItem> rows, {
  required String page,
  required int limit,
  required String? cursorMessageId,
  required bool ascending,
}) {
  final hasMore = rows.length > limit;
  final selected = rows.take(limit).toList(growable: false);
  return _MessagePage(
    messages: ascending ? selected : selected.reversed.toList(growable: false),
    page: page,
    limit: limit,
    hasMore: hasMore,
    cursorMessageId: cursorMessageId,
  );
}

Map<String, dynamic> _cursorPaginationToJson({
  required String page,
  required int limit,
  required bool hasMore,
  required String? cursorMessageId,
  required String? oldestMessageId,
  required String? newestMessageId,
}) => {
  'order': 'oldest_to_newest',
  'page': page,
  'limit': limit,
  'cursor_message_id': cursorMessageId,
  'has_more': hasMore,
  'has_more_direction': page == _messagePageAfter ? 'newer' : 'older',
  'oldest_message_id': oldestMessageId,
  'newest_message_id': newestMessageId,
  'older_page': oldestMessageId == null
      ? null
      : {
          'page': _messagePageBefore,
          'cursor_message_id': oldestMessageId,
        },
  'newer_page': newestMessageId == null
      ? null
      : {
          'page': _messagePageAfter,
          'cursor_message_id': newestMessageId,
        },
}..removeWhere((_, value) => value == null);

String _messagePage(Map<String, dynamic> arguments) {
  final page = _optionalString(arguments, 'page') ?? _messagePageLatest;
  return switch (page) {
    _messagePageLatest || _messagePageBefore || _messagePageAfter => page,
    _ => throw ArgumentError(
      'page must be one of latest, before, or after',
    ),
  };
}

String? _cursorMessageId(Map<String, dynamic> arguments, String page) {
  final cursorMessageId = _optionalString(arguments, 'cursor_message_id');
  if (page == _messagePageLatest) {
    if (cursorMessageId != null) {
      throw ArgumentError(
        'cursor_message_id is only valid when page is before or after',
      );
    }
    return null;
  }
  if (cursorMessageId == null) {
    throw ArgumentError('cursor_message_id is required when page is $page');
  }
  return cursorMessageId;
}

Future<_ConversationPage> _readConversationPage(
  Database database,
  Map<String, dynamic> arguments,
) async {
  final limit = _int(arguments, 'limit', defaultValue: 30, min: 1, max: 100);
  final query = _optionalString(arguments, 'query');
  final circleId = _optionalString(arguments, 'circle_id');
  final rows = query == null
      ? circleId == null
            ? await database.conversationDao.conversationItems().get()
            : await database.conversationDao
                  .conversationsByCircleId(circleId, _conversationScanLimit, 0)
                  .get()
      : await _searchConversations(database, query, _conversationScanLimit);
  final scopedRows = query == null || circleId == null
      ? rows
      : await _filterConversationsByCircle(database, rows, circleId);
  return _conversationPageFromRows(
    scopedRows,
    limit: limit,
    cursorConversationId: _optionalString(
      arguments,
      'cursor_conversation_id',
    ),
    order: query == null ? 'app_chat_list' : 'search_relevance',
  );
}

_ConversationPage _conversationPageFromRows(
  List<ConversationItem> rows, {
  required int limit,
  required String? cursorConversationId,
  required String order,
}) {
  final start = _cursorStartIndex(
    rows,
    cursorConversationId,
    (conversation) => conversation.conversationId,
    'cursor_conversation_id',
  );
  final selected = rows.skip(start).take(limit + 1).toList(growable: false);
  final hasMore = selected.length > limit;
  return _ConversationPage(
    conversations: selected.take(limit).toList(growable: false),
    limit: limit,
    hasMore: hasMore,
    order: order,
    cursorConversationId: cursorConversationId,
  );
}

Future<List<ConversationItem>> _filterConversationsByCircle(
  Database database,
  List<ConversationItem> rows,
  String circleId,
) async {
  final conversationIds = await database.conversationDao
      .conversationIdsByCircleId(circleId, limit: _conversationScanLimit);
  final conversationIdSet = conversationIds.toSet();
  return rows
      .where(
        (conversation) =>
            conversationIdSet.contains(conversation.conversationId),
      )
      .toList(growable: false);
}

_ParticipantPage _participantPageFromRows(
  List<ParticipantUser> rows, {
  required int limit,
  required String? cursorUserId,
}) {
  final sorted = [...rows]
    ..sort((a, b) {
      final name = _compareNullableText(a.fullName, b.fullName);
      if (name != 0) return name;
      final identityNumber = a.identityNumber.compareTo(b.identityNumber);
      if (identityNumber != 0) return identityNumber;
      return a.userId.compareTo(b.userId);
    });
  final start = _cursorStartIndex(
    sorted,
    cursorUserId,
    (participant) => participant.userId,
    'cursor_user_id',
  );
  final selected = sorted.skip(start).take(limit + 1).toList(growable: false);
  final hasMore = selected.length > limit;
  return _ParticipantPage(
    participants: selected.take(limit).toList(growable: false),
    limit: limit,
    hasMore: hasMore,
    cursorUserId: cursorUserId,
  );
}

int _cursorStartIndex<T>(
  List<T> rows,
  String? cursor,
  String Function(T row) idOf,
  String cursorName,
) {
  if (cursor == null) return 0;
  final index = rows.indexWhere((row) => idOf(row) == cursor);
  if (index < 0) throw ArgumentError('$cursorName not found');
  return index + 1;
}

int _compareNullableText(String? a, String? b) {
  final left = a?.trim().toLowerCase();
  final right = b?.trim().toLowerCase();
  if (left == null || left.isEmpty) {
    return right == null || right.isEmpty ? 0 : 1;
  }
  if (right == null || right.isEmpty) return -1;
  return left.compareTo(right);
}

Future<MessageOrderInfo> _messageOrderInfoForCursor(
  Database database,
  String conversationId,
  String? cursorMessageId,
) async {
  if (cursorMessageId == null) {
    throw ArgumentError('cursor_message_id is required');
  }
  final message = await _messageById(database, cursorMessageId);
  if (message.conversationId != conversationId) {
    throw ArgumentError('cursor_message_id is not in conversation_id');
  }
  final info = await database.messageDao.messageOrderInfo(cursorMessageId);
  if (info == null) throw StateError('Message order info not found');
  return info;
}

Future<ConversationItem> _conversationById(
  Database database,
  String conversationId,
) async {
  final conversation = await database.conversationDao
      .conversationItem(conversationId)
      .getSingleOrNull();
  if (conversation == null) throw StateError('Conversation not found');
  return conversation;
}

Future<ConversationItem> _resolveConversation(
  Database database,
  Map<String, dynamic> arguments,
) async {
  final conversationId = _optionalString(arguments, 'conversation_id');
  if (conversationId != null) {
    return _conversationById(database, conversationId);
  }
  final uri = _optionalString(arguments, 'uri');
  if (uri != null) {
    final parsed = Uri.tryParse(uri);
    final id = parsed?.host == 'conversations'
        ? parsed?.pathSegments.firstOrNull
        : null;
    if (id != null) return _conversationById(database, id);
  }
  final query = _requiredString(arguments, 'query');
  final result = await database.conversationDao
      .fuzzySearchConversation(query, 1)
      .getSingleOrNull();
  if (result == null) throw StateError('Conversation not found');
  return _conversationById(database, result.conversationId);
}

Future<List<ConversationItem>> _searchConversations(
  Database database,
  String query,
  int limit,
) async {
  final results = await database.conversationDao
      .fuzzySearchConversation(query, limit)
      .get();
  final conversations = <ConversationItem>[];
  for (final result in results) {
    final conversation = await database.conversationDao
        .conversationItem(result.conversationId)
        .getSingleOrNull();
    if (conversation != null) {
      conversations.add(conversation);
    }
  }
  return conversations;
}

Future<List<CircleConversationRequest>> _circleConversationRequests(
  Database database,
  List<String> conversationIds,
  CircleConversationAction action,
) async {
  final requests = <CircleConversationRequest>[];
  for (final conversationId in conversationIds) {
    final conversation = await _conversationById(database, conversationId);
    requests.add(
      CircleConversationRequest(
        conversationId: conversation.conversationId,
        action: action,
        userId: conversation.ownerId,
      ),
    );
  }
  return requests;
}

Future<MessageItem> _messageById(Database database, String messageId) async {
  final message = await database.messageDao
      .messageItemByMessageId(messageId)
      .getSingleOrNull();
  if (message == null) throw StateError('Message not found');
  return message;
}

Map<String, dynamic> _conversationToJson(ConversationItem conversation) => {
  'conversation_id': conversation.conversationId,
  'name': conversation.validName,
  'category': conversation.category?.name,
  'owner_id': conversation.ownerId,
  'owner_identity_number': conversation.ownerIdentityNumber,
  'unread_count': conversation.unseenMessageCount,
  'is_muted': conversation.isMute,
  'is_group': conversation.isGroupConversation,
  'last_read_message_id': conversation.lastReadMessageId,
  'created_at': _dateTime(conversation.createdAt),
  'last_message_created_at': _dateTime(conversation.lastMessageCreatedAt),
};

List<Map<String, dynamic>> _messagesToJson(
  Iterable<MessageItem> messages, {
  bool includePinState = false,
}) => messages
    .map((message) => _messageToJson(message, includePinState: includePinState))
    .toList(growable: false);

List<Map<String, dynamic>> _searchMessagesToJson(
  Iterable<SearchMessageDetailItem> messages,
) => messages
    .map(
      (message) => {
        'message_id': message.messageId,
        'conversation_id': message.conversationId,
        'conversation_name': message.groupName?.trim().isNotEmpty == true
            ? message.groupName
            : message.ownerFullName,
        'user_id': message.senderId,
        'user_full_name': message.senderFullName,
        'type': message.type,
        'content': message.content,
        'created_at': _dateTime(message.createdAt),
        'status': message.status.name,
        'media_name': message.mediaName,
      }..removeWhere((_, value) => value == null),
    )
    .toList(growable: false);

Map<String, dynamic> _messageToJson(
  MessageItem message, {
  bool includePinState = false,
}) => {
  'message_id': message.messageId,
  'conversation_id': message.conversationId,
  'user_id': message.userId,
  'user_full_name': message.userFullName,
  'user_identity_number': message.userIdentityNumber,
  'type': message.type,
  'content': _messageContent(message),
  'quote_message_id': message.quoteId,
  'quote_content': message.quoteContent,
  'caption': message.caption,
  'created_at': _dateTime(message.createdAt),
  'status': message.status.name,
  if (includePinState || message.pinned) 'is_pinned': message.pinned,
  'link': _linkPreviewToJson(message),
  'media': _hasAttachment(message) ? _attachmentToJson(message) : null,
}..removeWhere((_, value) => value == null);

String? _messageContent(MessageItem message) {
  final content = message.content;
  final type = message.type;
  if (content?.trim().isNotEmpty == true) return content;
  if (type.isImage) return '[image]';
  if (type.isVideo) return '[video] ${message.mediaName ?? ''}'.trim();
  if (type.isAudio) return '[audio]';
  if (type.isData) return '[file] ${message.mediaName ?? ''}'.trim();
  if (type.isSticker) return '[sticker]';
  return content;
}

bool _hasAttachment(MessageItem message) {
  final type = message.type;
  return type.isImage || type.isVideo || type.isAudio || type.isData;
}

Map<String, dynamic> _attachmentToJson(MessageItem message) => {
  'message_id': message.messageId,
  'conversation_id': message.conversationId,
  'type': message.type,
  'name': message.mediaName,
  'mime_type': message.mediaMimeType,
  'size': message.mediaSize,
  'width': message.mediaWidth,
  'height': message.mediaHeight,
  'duration': message.mediaDuration,
  'status': message.mediaStatus?.name,
  'created_at': _dateTime(message.createdAt),
}..removeWhere((_, value) => value == null);

Map<String, dynamic>? _linkPreviewToJson(MessageItem message) {
  final link = {
    'site_name': message.siteName,
    'title': message.siteTitle,
    'description': message.siteDescription,
    'image': message.siteImage,
  }..removeWhere((_, value) => value == null);
  return link.isEmpty ? null : link;
}

Map<String, dynamic> _participantToJson(ParticipantUser participant) => {
  'conversation_id': participant.conversationId,
  'user_id': participant.userId,
  'identity_number': participant.identityNumber,
  'full_name': participant.fullName,
  'role': participant.role?.name,
  'relationship': participant.relationship?.name,
  'biography': participant.biography,
  'avatar_url': participant.avatarUrl,
  'is_verified': participant.isVerified,
  'is_bot': participant.appId != null,
  'app_id': participant.appId,
  'membership': participant.membership?.toJson(),
  'created_at': _dateTime(participant.createdAt),
}..removeWhere((_, value) => value == null);

bool _participantMatches(ParticipantUser participant, String query) {
  final needle = query.toLowerCase();
  return participant.userId.toLowerCase().contains(needle) ||
      participant.identityNumber.toLowerCase().contains(needle) ||
      (participant.fullName?.toLowerCase().contains(needle) ?? false);
}

Map<String, dynamic> _circleToJson(ConversationCircleItem circle) => {
  'circle_id': circle.circleId,
  'name': circle.name,
  'conversation_count': circle.count,
  'unseen_conversation_count': circle.unseenConversationCount,
  'unseen_muted_conversation_count': circle.unseenMutedConversationCount,
  'created_at': _dateTime(circle.createdAt),
  'ordered_at': _dateTime(circle.orderedAt),
};

Map<String, dynamic> _aiThreadToJson(AiChatThread thread) => {
  'thread_id': thread.id,
  'conversation_id': thread.conversationId,
  'title': thread.title,
  'summary': thread.summary,
  'last_message_preview': thread.lastMessagePreview,
  'message_count': thread.messageCount,
  'created_at': _dateTime(thread.createdAt),
  'updated_at': _dateTime(thread.updatedAt),
  'last_message_at': _dateTime(thread.lastMessageAt),
}..removeWhere((_, value) => value == null);

Map<String, dynamic> _aiMessageToJson(AiChatMessage message) => {
  'message_id': message.id,
  'thread_id': message.threadId,
  'conversation_id': message.conversationId,
  'role': message.role,
  'provider_id': message.providerId,
  'model': message.model,
  'content': message.content,
  'status': message.status,
  'error_text': message.errorText,
  'metadata': message.metadata,
  'created_at': _dateTime(message.createdAt),
  'updated_at': _dateTime(message.updatedAt),
}..removeWhere((_, value) => value == null);

String? _dateTime(DateTime? value) => value?.toIso8601String();

String _requiredString(Map<String, dynamic> arguments, String key) {
  final value = _optionalString(arguments, key);
  if (value == null || value.isEmpty) {
    throw ArgumentError('$key is required');
  }
  return value;
}

String? _optionalString(Map<String, dynamic> arguments, String key) {
  final value = arguments[key];
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

List<String> _requiredStringList(Map<String, dynamic> arguments, String key) {
  final list = _optionalStringList(arguments, key);
  if (list.isEmpty) throw ArgumentError('$key is required');
  return list;
}

List<String> _optionalStringList(Map<String, dynamic> arguments, String key) {
  final value = arguments[key];
  if (value == null) return const [];
  if (value is Iterable) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return value
      .toString()
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

bool _bool(
  Map<String, dynamic> arguments,
  String key, {
  bool defaultValue = false,
}) {
  final value = arguments[key];
  if (value == null) return defaultValue;
  if (value is bool) return value;
  final text = value.toString().trim().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return defaultValue;
}

int _int(
  Map<String, dynamic> arguments,
  String key, {
  required int defaultValue,
  int min = 0,
  int max = 1 << 31,
}) {
  final value = arguments[key];
  final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
  return (parsed ?? defaultValue).clamp(min, max);
}

DateTime? _date(Map<String, dynamic> arguments, String key) {
  final text = _optionalString(arguments, key);
  return text == null ? null : DateTime.parse(text);
}

Map<String, dynamic> _jsonMap(dynamic json) {
  if (json == null) return <String, dynamic>{};
  if (json is Map<String, dynamic>) return json;
  if (json is Map) return json.cast<String, dynamic>();
  throw ArgumentError('Expected JSON object');
}

const _emptyObjectSchema = {
  'type': 'object',
  'properties': <String, Object>{},
  'additionalProperties': false,
};

const _stringArraySchema = {
  'type': 'array',
  'items': {'type': 'string'},
};

const _conversationIdProperty = {
  'type': 'string',
  'description':
      'Mixin conversation_id. Use mixin_resolve_conversation first when only a name or mixin:// URL is known.',
};

const _messageIdProperty = {
  'type': 'string',
  'description': 'Mixin message_id.',
};

const _limit100Property = {
  'type': 'integer',
  'description': 'Maximum number of items to return.',
  'default': 100,
  'minimum': 1,
  'maximum': 200,
};

const _limit50Property = {
  'type': 'integer',
  'description': 'Maximum number of items to return.',
  'default': 50,
  'minimum': 1,
  'maximum': 200,
};

const _limit30Property = {
  'type': 'integer',
  'description': 'Maximum number of items to return.',
  'default': 30,
  'minimum': 1,
  'maximum': 100,
};

const _conversationCursorProperty = {
  'type': 'string',
  'description':
      'Optional cursor for the next page. Use pagination.next_cursor_conversation_id from the previous result.',
};

const _participantCursorProperty = {
  'type': 'string',
  'description':
      'Optional cursor for the next page. Use pagination.next_cursor_user_id from the previous result.',
};

const _messageCursorProperties = {
  'page': {
    'type': 'string',
    'enum': [_messagePageLatest, _messagePageBefore, _messagePageAfter],
    'default': _messagePageLatest,
    'description':
        'latest returns the latest matching messages. before returns messages older than cursor_message_id. after returns messages newer than cursor_message_id. Results are always oldest_to_newest.',
  },
  'cursor_message_id': {
    'type': 'string',
    'description':
        'Required when page is before or after. Use pagination.older_page.cursor_message_id or pagination.newer_page.cursor_message_id from the previous result.',
  },
  'limit': _limit100Property,
};

const _conversationRangeProperties = {
  'conversation_id': _conversationIdProperty,
  'start': {
    'type': 'string',
    'format': 'date-time',
    'description': 'Inclusive ISO-8601 lower bound for message created_at.',
  },
  'end': {
    'type': 'string',
    'format': 'date-time',
    'description': 'Exclusive ISO-8601 upper bound for message created_at.',
  },
};

const _toolSpecs = [
  _Tool(
    'mixin_get_app_status',
    'Get login state, app version, active conversation ids, permission scopes, and enabled MCP tools.',
  ),
  _Tool(
    'mixin_list_conversations',
    'List conversations. Without query, returns app chat-list order. With query, searches conversations. With circle_id, restricts results to that circle. Use cursor_conversation_id to continue.',
    properties: {
      'query': {
        'type': 'string',
        'description':
            'Optional fuzzy conversation name search. Omit to list conversations.',
      },
      'circle_id': {
        'type': 'string',
        'description':
            'Optional circle id from mixin_list_circles. When set, only conversations in that circle are returned.',
      },
      'limit': _limit30Property,
      'cursor_conversation_id': _conversationCursorProperty,
    },
  ),
  _Tool(
    'mixin_get_conversation',
    'Get one conversation by conversation_id.',
    required: ['conversation_id'],
    properties: {
      'conversation_id': _conversationIdProperty,
    },
  ),
  _Tool(
    'mixin_resolve_conversation',
    'Resolve exactly one conversation from conversation_id, mixin://conversations/<id>, or a fuzzy query. Provide one of conversation_id, uri, or query.',
    properties: {
      'conversation_id': _conversationIdProperty,
      'uri': {
        'type': 'string',
        'description':
            'Mixin URI such as mixin://conversations/<conversation_id>.',
      },
      'query': {
        'type': 'string',
        'description':
            'Fuzzy conversation name search. Returns the best match.',
      },
    },
    schema: {
      'oneOf': [
        {
          'required': ['conversation_id'],
        },
        {
          'required': ['uri'],
        },
        {
          'required': ['query'],
        },
      ],
    },
  ),
  _Tool(
    'mixin_get_conversation_stats',
    'Get message_count, first_message_at, and last_message_at for a conversation and optional time range.',
    required: ['conversation_id'],
    properties: _conversationRangeProperties,
  ),
  _Tool(
    'mixin_list_messages',
    'List or search messages. With query, searches globally or inside conversation_id/circle_id. Without query, conversation_id is required and messages are listed by cursor. Use kind to list all messages, attachments, pinned messages, mentions, or links.',
    properties: {
      ..._conversationRangeProperties,
      ..._messageCursorProperties,
      'query': {
        'type': 'string',
        'description':
            'Optional search text. When omitted, conversation_id is required and the tool lists messages from that conversation.',
      },
      'circle_id': {
        'type': 'string',
        'description': 'Optional search scope. Only applies when query is set.',
      },
      'kind': {
        'type': 'string',
        'enum': [
          _messageKindAll,
          _messageKindAttachments,
          _messageKindPinned,
          _messageKindMentions,
          _messageKindLinks,
        ],
        'default': _messageKindAll,
        'description':
            'Message filter. For search, only all and attachments are supported. For conversation listing, all values are supported.',
      },
      'sender_id': {
        'type': 'string',
        'description': 'Optional sender user_id filter.',
      },
      'sender_identity_number': {
        'type': 'string',
        'description':
            'Optional sender identity number filter. Only applies when query is omitted.',
      },
      'message_types': {
        ..._stringArraySchema,
        'description': 'Optional Mixin message category filters.',
      },
      'include_pin_state': {
        'type': 'boolean',
        'default': false,
        'description': 'Whether every returned message includes is_pinned.',
      },
      'unread_only': {
        'type': 'boolean',
        'default': false,
        'description': 'Only applies when kind is mentions.',
      },
    },
  ),
  _Tool(
    'mixin_get_message',
    'Get a message by message_id.',
    required: ['message_id'],
    properties: {
      'message_id': _messageIdProperty,
    },
  ),
  _Tool(
    'mixin_get_message_context',
    'Read messages immediately before and after one message_id.',
    required: ['message_id'],
    properties: {
      'message_id': _messageIdProperty,
      'limit': {
        'type': 'integer',
        'description':
            'Number of messages to read before and after the target.',
        'default': 10,
        'minimum': 1,
        'maximum': 50,
      },
    },
  ),
  _Tool(
    'mixin_read_image_message_text',
    'Run local OCR for one image message.',
    required: ['conversation_id', 'message_id'],
    properties: {
      'conversation_id': _conversationIdProperty,
      'message_id': _messageIdProperty,
    },
  ),
  _Tool(
    'mixin_list_conversation_participants',
    'List or search participants in a conversation. Results are ordered by full_name, identity_number, then user_id.',
    required: ['conversation_id'],
    properties: {
      'conversation_id': _conversationIdProperty,
      'query': {
        'type': 'string',
        'description': 'Optional user_id, identity number, or name search.',
      },
      'limit': _limit50Property,
      'cursor_user_id': _participantCursorProperty,
    },
  ),
  _Tool(
    'mixin_resolve_conversation_participant',
    'Resolve participants in one conversation by user_id, identity number, or name.',
    required: ['conversation_id', 'query'],
    properties: {
      'conversation_id': _conversationIdProperty,
      'query': {
        'type': 'string',
        'description': 'User id, identity number, or name.',
      },
      'limit': {
        'type': 'integer',
        'description': 'Maximum number of matching participants to return.',
        'default': 5,
        'minimum': 1,
        'maximum': 20,
      },
    },
  ),
  _Tool(
    'mixin_list_circles',
    'List local circles and their conversation counts.',
  ),
  _Tool(
    'mixin_open_conversation',
    'Open a conversation in the Mixin UI.',
    scope: _McpPermissionScope.appControl,
    required: ['conversation_id'],
    properties: {
      'conversation_id': _conversationIdProperty,
    },
  ),
  _Tool(
    'mixin_reveal_message',
    'Open the message conversation and reveal the message in the Mixin UI.',
    scope: _McpPermissionScope.appControl,
    required: ['message_id'],
    properties: {
      'message_id': _messageIdProperty,
    },
  ),
  _Tool(
    'mixin_get_conversation_draft',
    'Get the current draft text for a conversation.',
    scope: _McpPermissionScope.draftWrite,
    required: ['conversation_id'],
    properties: {
      'conversation_id': _conversationIdProperty,
    },
  ),
  _Tool(
    'mixin_set_conversation_draft',
    'Replace the draft text for a conversation. Does not send.',
    scope: _McpPermissionScope.draftWrite,
    required: ['conversation_id', 'text'],
    properties: {
      'conversation_id': _conversationIdProperty,
      'text': {
        'type': 'string',
        'description': 'Draft text. This never sends a message.',
      },
    },
  ),
  _Tool(
    'mixin_insert_conversation_text',
    'Insert text into the active input, or append to stored draft.',
    scope: _McpPermissionScope.draftWrite,
    required: ['conversation_id', 'text'],
    properties: {
      'conversation_id': _conversationIdProperty,
      'text': {
        'type': 'string',
        'description': 'Text to insert. This never sends a message.',
      },
    },
  ),
  _Tool(
    'mixin_clear_conversation_draft',
    'Clear the draft text for a conversation. Does not send.',
    scope: _McpPermissionScope.draftWrite,
    required: ['conversation_id'],
    properties: {
      'conversation_id': _conversationIdProperty,
    },
  ),
  _Tool(
    'mixin_create_circle',
    'Create a circle, optionally with initial conversations.',
    scope: _McpPermissionScope.circleManagement,
    required: ['name'],
    properties: {
      'name': {
        'type': 'string',
        'description': 'Circle name.',
      },
      'conversation_ids': {
        ..._stringArraySchema,
        'description': 'Optional initial conversation_ids.',
      },
    },
  ),
  _Tool(
    'mixin_rename_circle',
    'Rename a circle.',
    scope: _McpPermissionScope.circleManagement,
    required: ['circle_id', 'name'],
    properties: {
      'circle_id': {'type': 'string'},
      'name': {'type': 'string'},
    },
  ),
  _Tool(
    'mixin_delete_circle',
    'Delete a circle.',
    scope: _McpPermissionScope.circleManagement,
    required: ['circle_id'],
    properties: {
      'circle_id': {'type': 'string'},
    },
  ),
  _Tool(
    'mixin_add_conversations_to_circle',
    'Add conversations to a circle.',
    scope: _McpPermissionScope.circleManagement,
    required: ['circle_id', 'conversation_ids'],
    properties: {
      'circle_id': {'type': 'string'},
      'conversation_ids': {
        ..._stringArraySchema,
        'description': 'Conversation ids to add.',
      },
    },
  ),
  _Tool(
    'mixin_remove_conversations_from_circle',
    'Remove conversations from a circle.',
    scope: _McpPermissionScope.circleManagement,
    required: ['circle_id', 'conversation_ids'],
    properties: {
      'circle_id': {'type': 'string'},
      'conversation_ids': {
        ..._stringArraySchema,
        'description': 'Conversation ids to remove.',
      },
    },
  ),
  _Tool(
    'mixin_attach_message_to_ai_context',
    'Attach a message to the app AI context chip for its conversation.',
    scope: _McpPermissionScope.appControl,
    required: ['message_id'],
    properties: {
      'message_id': _messageIdProperty,
    },
  ),
  _Tool(
    'mixin_list_conversation_ai_threads',
    'List AI threads for a conversation.',
    required: ['conversation_id'],
    properties: {
      'conversation_id': _conversationIdProperty,
    },
  ),
  _Tool(
    'mixin_read_ai_thread',
    'Read one AI thread and its messages.',
    required: ['thread_id'],
    properties: {
      'thread_id': {'type': 'string'},
    },
  ),
  _Tool(
    'mixin_get_ai_message_tool_events',
    'Read stored AI tool call/result events for an AI message.',
    required: ['message_id'],
    properties: {
      'message_id': _messageIdProperty,
    },
  ),
];

class _Tool {
  const _Tool(
    this.name,
    this.description, {
    this.scope = _McpPermissionScope.read,
    this.required = const [],
    this.properties = const <String, Object>{},
    this.schema = const <String, Object>{},
  });

  final String name;
  final String description;
  final _McpPermissionScope scope;
  final List<String> required;
  final Map<String, Object> properties;
  final Map<String, Object> schema;

  Map<String, Object?> get inputSchema => {
    ..._emptyObjectSchema,
    'properties': properties,
    'required': required,
    ...schema,
  };
}
