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
import '../extension/extension.dart';
import '../logger.dart';
import '../system/package_info.dart';
import 'mixin_mcp_bridge.dart';

typedef CurrentConversationIdResolver = String? Function();

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
        final query = _optionalString(arguments, 'query');
        final circleId = _optionalString(arguments, 'circle_id');
        final limit = _int(
          arguments,
          'limit',
          defaultValue: 30,
          min: 1,
          max: 100,
        );
        final offset = _int(arguments, 'offset', defaultValue: 0);
        final conversations = circleId != null
            ? await database.conversationDao
                  .conversationsByCircleId(circleId, limit, offset)
                  .get()
            : query == null || query.trim().isEmpty
            ? await database.conversationDao.conversationItems().get()
            : await _searchConversations(database, query, offset + limit);
        return {
          'conversations': conversations
              .skip(circleId == null ? offset : 0)
              .take(limit)
              .map(_conversationToJson)
              .toList(growable: false),
        };
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
      case 'mixin_read_messages':
        final messages = await database.messageDao
            .messagesByConversationIdAndCreatedAtRange(
              _requiredString(arguments, 'conversation_id'),
              offset: _int(arguments, 'offset', defaultValue: 0),
              limit: _int(
                arguments,
                'limit',
                defaultValue: 50,
                min: 1,
                max: 200,
              ),
              startInclusive: _date(arguments, 'start'),
              endExclusive: _date(arguments, 'end'),
              senderId: _optionalString(arguments, 'sender_id'),
              senderIdentityNumber: _optionalString(
                arguments,
                'sender_identity_number',
              ),
              categories: _optionalStringList(arguments, 'message_types'),
            )
            .get();
        return {
          'messages': _messagesToJson(
            messages,
            includePinState: _bool(arguments, 'include_pin_state'),
          ),
        };
      case 'mixin_search_messages':
        final conversationId = _optionalString(arguments, 'conversation_id');
        final circleId = _optionalString(arguments, 'circle_id');
        final conversationIds = conversationId == null
            ? circleId == null
                  ? const <String>[]
                  : await database.conversationDao.conversationIdsByCircleId(
                      circleId,
                    )
            : [conversationId];
        if (circleId != null && conversationIds.isEmpty) {
          return {'messages': const <Map<String, dynamic>>[]};
        }
        final messages = await database.fuzzySearchMessage(
          query: _requiredString(arguments, 'query'),
          limit: _int(arguments, 'limit', defaultValue: 20, min: 1, max: 50),
          conversationIds: conversationIds,
          userId: _optionalString(arguments, 'sender_id'),
          categories: _optionalStringList(arguments, 'message_types'),
          anchorMessageId: _optionalString(arguments, 'anchor_id'),
        );
        return {'messages': _searchMessagesToJson(messages)};
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
      case 'mixin_read_image_text':
        final result = await _conversationTools.readImageText(
          conversationId: _requiredString(arguments, 'conversation_id'),
          messageId: _requiredString(arguments, 'message_id'),
        );
        return result.toJson();
      case 'mixin_list_attachments':
        final messages = await database.messageDao
            .attachmentMessagesByConversationId(
              _requiredString(arguments, 'conversation_id'),
              offset: _int(arguments, 'offset', defaultValue: 0),
              limit: _int(
                arguments,
                'limit',
                defaultValue: 50,
                min: 1,
                max: 200,
              ),
              startInclusive: _date(arguments, 'start'),
              endExclusive: _date(arguments, 'end'),
              senderId: _optionalString(arguments, 'sender_id'),
              senderIdentityNumber: _optionalString(
                arguments,
                'sender_identity_number',
              ),
              categories: _optionalStringList(arguments, 'message_types'),
            )
            .get();
        return {
          'attachments': messages
              .where(_hasAttachment)
              .map(_attachmentToJson)
              .toList(growable: false),
        };
      case 'mixin_list_pinned_messages':
        final conversationId = _requiredString(arguments, 'conversation_id');
        final pins = await database.pinMessageDao.pinMessagesByConversationId(
          conversationId: conversationId,
          limit: _int(arguments, 'limit', defaultValue: 50, min: 1, max: 200),
          offset: _int(arguments, 'offset', defaultValue: 0),
        );
        final messageIds = pins.map((pin) => pin.messageId).toList();
        final messages = await database.messageDao
            .messageItemByMessageIds(messageIds)
            .get();
        final messagesById = {
          for (final message in messages) message.messageId: message,
        };
        return {
          'messages': pins
              .map((pin) {
                final message = messagesById[pin.messageId];
                if (message == null) return null;
                return {
                  ..._messageToJson(message, includePinState: true),
                  'pinned_at': _dateTime(pin.createdAt),
                };
              })
              .nonNulls
              .toList(growable: false),
        };
      case 'mixin_list_participants':
        final query = _optionalString(arguments, 'query');
        final offset = _int(arguments, 'offset', defaultValue: 0);
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
        return {
          'participants': filtered
              .skip(offset)
              .take(limit)
              .map(_participantToJson)
              .toList(growable: false),
        };
      case 'mixin_resolve_user_in_conversation':
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
      case 'mixin_list_circle_conversations':
        final circleId = _requiredString(arguments, 'circle_id');
        final limit = _int(
          arguments,
          'limit',
          defaultValue: 50,
          min: 1,
          max: 200,
        );
        final offset = _int(arguments, 'offset', defaultValue: 0);
        final conversations = await database.conversationDao
            .conversationsByCircleId(circleId, limit, offset)
            .get();
        return {
          'circle_id': circleId,
          'conversations': conversations
              .map(_conversationToJson)
              .toList(growable: false),
        };
      case 'mixin_read_mentions':
        final messages = await database.messageDao
            .mentionMessagesByConversationId(
              _requiredString(arguments, 'conversation_id'),
              limit: _int(
                arguments,
                'limit',
                defaultValue: 50,
                min: 1,
                max: 200,
              ),
              offset: _int(arguments, 'offset', defaultValue: 0),
              unreadOnly: _bool(arguments, 'unread_only'),
            )
            .get();
        return {
          'messages': _messagesToJson(messages, includePinState: true),
        };
      case 'mixin_list_links':
        final messages = await database.messageDao
            .linkMessagesByConversationId(
              _requiredString(arguments, 'conversation_id'),
              limit: _int(
                arguments,
                'limit',
                defaultValue: 50,
                min: 1,
                max: 200,
              ),
              offset: _int(arguments, 'offset', defaultValue: 0),
            )
            .get();
        return {
          'links': messages.map(_linkToJson).toList(growable: false),
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
      case 'mixin_get_draft':
        final conversationId = _requiredString(arguments, 'conversation_id');
        return {
          'conversation_id': conversationId,
          'draft': await MixinMcpBridge.instance.getDraft(
            database,
            conversationId,
          ),
        };
      case 'mixin_set_draft':
        final conversationId = _requiredString(arguments, 'conversation_id');
        await MixinMcpBridge.instance.setDraft(
          database,
          conversationId,
          _requiredString(arguments, 'text'),
        );
        return {'updated': true, 'conversation_id': conversationId};
      case 'mixin_insert_text':
        final conversationId = _requiredString(arguments, 'conversation_id');
        await MixinMcpBridge.instance.insertText(
          database,
          conversationId,
          _requiredString(arguments, 'text'),
        );
        return {'updated': true, 'conversation_id': conversationId};
      case 'mixin_clear_draft':
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
      case 'mixin_attach_message_to_ai':
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
      case 'mixin_list_ai_threads':
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
      case 'mixin_get_ai_tool_events':
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
          content: [mcp.TextContent(text: const JsonEncoder().convert(data))],
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

Map<String, dynamic> _linkToJson(MessageItem message) => {
  ..._messageToJson(message, includePinState: true),
  'link': _linkPreviewToJson(message),
}..removeWhere((_, value) => value == null);

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

const _toolSpecs = [
  _Tool(
    'mixin_get_app_status',
    'Get login, active conversation, app version, and MCP capability status.',
  ),
  _Tool(
    'mixin_list_conversations',
    'List recent conversations, search conversations, or list a circle.',
    properties: {
      'query': {'type': 'string'},
      'circle_id': {'type': 'string'},
      'offset': {'type': 'integer'},
      'limit': {'type': 'integer'},
    },
  ),
  _Tool(
    'mixin_get_conversation',
    'Get one conversation by conversation_id.',
    required: ['conversation_id'],
    properties: {
      'conversation_id': {'type': 'string'},
    },
  ),
  _Tool(
    'mixin_resolve_conversation',
    'Resolve a conversation from conversation_id, mixin URI, or query.',
    properties: {
      'conversation_id': {'type': 'string'},
      'uri': {'type': 'string'},
      'query': {'type': 'string'},
    },
  ),
  _Tool(
    'mixin_get_conversation_stats',
    'Get message count and first/last timestamps for a conversation.',
    required: ['conversation_id'],
    properties: _conversationRangeProperties,
  ),
  _Tool(
    'mixin_read_messages',
    'Read conversation messages by range, sender, type, offset, and limit.',
    required: ['conversation_id'],
    properties: {
      ..._conversationRangeProperties,
      'sender_id': {'type': 'string'},
      'sender_identity_number': {'type': 'string'},
      'message_types': _stringArraySchema,
      'include_pin_state': {'type': 'boolean'},
      'offset': {'type': 'integer'},
      'limit': {'type': 'integer'},
    },
  ),
  _Tool(
    'mixin_search_messages',
    'Search messages globally, inside a conversation, or inside a circle.',
    required: ['query'],
    properties: {
      'query': {'type': 'string'},
      'conversation_id': {'type': 'string'},
      'circle_id': {'type': 'string'},
      'sender_id': {'type': 'string'},
      'message_types': _stringArraySchema,
      'limit': {'type': 'integer'},
      'anchor_id': {'type': 'string'},
    },
  ),
  _Tool(
    'mixin_get_message',
    'Get a message by message_id.',
    required: ['message_id'],
    properties: {
      'message_id': {'type': 'string'},
    },
  ),
  _Tool(
    'mixin_get_message_context',
    'Read messages around a message_id.',
    required: ['message_id'],
    properties: {
      'message_id': {'type': 'string'},
      'limit': {'type': 'integer'},
    },
  ),
  _Tool(
    'mixin_read_image_text',
    'Run local OCR for an image message.',
    required: ['conversation_id', 'message_id'],
    properties: {
      'conversation_id': {'type': 'string'},
      'message_id': {'type': 'string'},
    },
  ),
  _Tool(
    'mixin_list_attachments',
    'List attachment metadata for a conversation.',
    required: ['conversation_id'],
    properties: {
      ..._conversationRangeProperties,
      'sender_id': {'type': 'string'},
      'sender_identity_number': {'type': 'string'},
      'message_types': _stringArraySchema,
      'offset': {'type': 'integer'},
      'limit': {'type': 'integer'},
    },
  ),
  _Tool(
    'mixin_list_pinned_messages',
    'List pinned messages for a conversation.',
    required: ['conversation_id'],
    properties: {
      'conversation_id': {'type': 'string'},
      'offset': {'type': 'integer'},
      'limit': {'type': 'integer'},
    },
  ),
  _Tool(
    'mixin_list_participants',
    'List or search participants in a conversation.',
    required: ['conversation_id'],
    properties: {
      'conversation_id': {'type': 'string'},
      'query': {'type': 'string'},
      'offset': {'type': 'integer'},
      'limit': {'type': 'integer'},
    },
  ),
  _Tool(
    'mixin_resolve_user_in_conversation',
    'Resolve participants by user_id, identity number, or name.',
    required: ['conversation_id', 'query'],
    properties: {
      'conversation_id': {'type': 'string'},
      'query': {'type': 'string'},
      'limit': {'type': 'integer'},
    },
  ),
  _Tool(
    'mixin_list_circles',
    'List local circles and their conversation counts.',
  ),
  _Tool(
    'mixin_list_circle_conversations',
    'List conversations in a circle.',
    required: ['circle_id'],
    properties: {
      'circle_id': {'type': 'string'},
      'offset': {'type': 'integer'},
      'limit': {'type': 'integer'},
    },
  ),
  _Tool(
    'mixin_read_mentions',
    'Read mention messages in a conversation without marking them read.',
    required: ['conversation_id'],
    properties: {
      'conversation_id': {'type': 'string'},
      'unread_only': {'type': 'boolean'},
      'offset': {'type': 'integer'},
      'limit': {'type': 'integer'},
    },
  ),
  _Tool(
    'mixin_list_links',
    'List messages with link previews in a conversation.',
    required: ['conversation_id'],
    properties: {
      'conversation_id': {'type': 'string'},
      'offset': {'type': 'integer'},
      'limit': {'type': 'integer'},
    },
  ),
  _Tool(
    'mixin_open_conversation',
    'Open a conversation in the Mixin UI.',
    scope: _McpPermissionScope.appControl,
    required: ['conversation_id'],
    properties: {
      'conversation_id': {'type': 'string'},
    },
  ),
  _Tool(
    'mixin_reveal_message',
    'Open the message conversation and reveal the message in the Mixin UI.',
    scope: _McpPermissionScope.appControl,
    required: ['message_id'],
    properties: {
      'message_id': {'type': 'string'},
    },
  ),
  _Tool(
    'mixin_get_draft',
    'Get the current draft text for a conversation.',
    scope: _McpPermissionScope.draftWrite,
    required: ['conversation_id'],
    properties: {
      'conversation_id': {'type': 'string'},
    },
  ),
  _Tool(
    'mixin_set_draft',
    'Replace the draft text for a conversation. Does not send.',
    scope: _McpPermissionScope.draftWrite,
    required: ['conversation_id', 'text'],
    properties: {
      'conversation_id': {'type': 'string'},
      'text': {'type': 'string'},
    },
  ),
  _Tool(
    'mixin_insert_text',
    'Insert text into the active input, or append to stored draft.',
    scope: _McpPermissionScope.draftWrite,
    required: ['conversation_id', 'text'],
    properties: {
      'conversation_id': {'type': 'string'},
      'text': {'type': 'string'},
    },
  ),
  _Tool(
    'mixin_clear_draft',
    'Clear the draft text for a conversation. Does not send.',
    scope: _McpPermissionScope.draftWrite,
    required: ['conversation_id'],
    properties: {
      'conversation_id': {'type': 'string'},
    },
  ),
  _Tool(
    'mixin_create_circle',
    'Create a circle, optionally with initial conversations.',
    scope: _McpPermissionScope.circleManagement,
    required: ['name'],
    properties: {
      'name': {'type': 'string'},
      'conversation_ids': _stringArraySchema,
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
      'conversation_ids': _stringArraySchema,
    },
  ),
  _Tool(
    'mixin_remove_conversations_from_circle',
    'Remove conversations from a circle.',
    scope: _McpPermissionScope.circleManagement,
    required: ['circle_id', 'conversation_ids'],
    properties: {
      'circle_id': {'type': 'string'},
      'conversation_ids': _stringArraySchema,
    },
  ),
  _Tool(
    'mixin_attach_message_to_ai',
    'Attach a message to the app AI context chip for its conversation.',
    scope: _McpPermissionScope.appControl,
    required: ['message_id'],
    properties: {
      'message_id': {'type': 'string'},
    },
  ),
  _Tool(
    'mixin_list_ai_threads',
    'List AI threads for a conversation.',
    required: ['conversation_id'],
    properties: {
      'conversation_id': {'type': 'string'},
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
    'mixin_get_ai_tool_events',
    'Read stored AI tool call/result events for an AI message.',
    required: ['message_id'],
    properties: {
      'message_id': {'type': 'string'},
    },
  ),
];

const _conversationRangeProperties = {
  'conversation_id': {'type': 'string'},
  'start': {'type': 'string', 'description': 'Inclusive ISO-8601 timestamp.'},
  'end': {'type': 'string', 'description': 'Exclusive ISO-8601 timestamp.'},
};

class _Tool {
  const _Tool(
    this.name,
    this.description, {
    this.scope = _McpPermissionScope.read,
    this.required = const [],
    this.properties = const <String, Object>{},
  });

  final String name;
  final String description;
  final _McpPermissionScope scope;
  final List<String> required;
  final Map<String, Object> properties;

  Map<String, Object?> get inputSchema => {
    ..._emptyObjectSchema,
    'properties': properties,
    'required': required,
  };
}
