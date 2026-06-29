import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/extension/extension.dart';
import '../../utils/mcp/mixin_mcp_server.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../../widgets/toast.dart';
import '../provider/database_provider.dart';

class AiMcpSettingsPage extends HookConsumerWidget {
  const AiMcpSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider).requireValue;
    useListenable(database.settingProperties);
    final mcpServer = useListenable(MixinMcpServer.instance);
    final settings = database.settingProperties;
    final enableMcpServer = settings.enableMcpServer;
    final mcpEndpoint =
        mcpServer.endpoint?.toString() ?? _defaultMcpEndpointText;
    final mcpToken = settings.mcpServerToken;
    final mcpError = mcpServer.lastStartError;
    final tools = MixinMcpServer.toolInfos(database);
    final enabledToolCount = tools.where((tool) => tool.enabled).length;
    final statusText = _serverStatusText(
      enabled: enableMcpServer,
      running: mcpServer.isRunning,
      error: mcpError,
    );

    return Scaffold(
      backgroundColor: context.theme.background,
      appBar: const MixinAppBar(title: Text('Local MCP Server')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CellGroup(
                    padding: const EdgeInsets.only(right: 10, left: 10),
                    cellBackgroundColor:
                        context.theme.settingCellBackgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusText == 'Running'
                                ? 'Running on localhost'
                                : statusText,
                            style: TextStyle(
                              color: context.theme.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Exposes Mixin desktop tools to local MCP clients at $_defaultMcpEndpointText. It never sends messages.',
                            style: TextStyle(
                              color: context.theme.secondaryText,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          if (enableMcpServer && mcpError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Failed to bind port ${MixinMcpServer.defaultPort}.',
                              style: TextStyle(
                                color: context.theme.red,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  CellGroup(
                    padding: const EdgeInsets.only(right: 10, left: 10),
                    cellBackgroundColor:
                        context.theme.settingCellBackgroundColor,
                    child: Column(
                      children: [
                        CellItem(
                          title: const Text('Server'),
                          description: Text(statusText),
                          trailing: Transform.scale(
                            scale: 0.7,
                            child: CupertinoSwitch(
                              activeTrackColor: context.theme.accent,
                              value: enableMcpServer,
                              onChanged: (value) {
                                settings.enableMcpServer = value;
                              },
                            ),
                          ),
                        ),
                        if (enableMcpServer) ...[
                          _Divider(),
                          CellItem(
                            title: const Text('Endpoint'),
                            description: Expanded(
                              child: Text(
                                mcpEndpoint,
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            trailing: IconButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: mcpEndpoint),
                                );
                                showToastSuccessful();
                              },
                              icon: Icon(
                                Icons.copy_rounded,
                                color: context.theme.icon,
                              ),
                            ),
                          ),
                          _Divider(),
                          CellItem(
                            title: const Text('Access Token'),
                            description: Expanded(
                              child: Text(
                                _maskedToken(mcpToken),
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: mcpToken == null
                                      ? null
                                      : () {
                                          Clipboard.setData(
                                            ClipboardData(text: mcpToken),
                                          );
                                          showToastSuccessful();
                                        },
                                  icon: Icon(
                                    Icons.copy_rounded,
                                    color: context.theme.icon,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    settings.regenerateMcpServerToken();
                                    showToastSuccessful();
                                  },
                                  icon: Icon(
                                    Icons.refresh_rounded,
                                    color: context.theme.icon,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _Divider(),
                          CellItem(
                            title: const Text('Draft Editing'),
                            description: const Text('Draft write tools'),
                            trailing: Transform.scale(
                              scale: 0.7,
                              child: CupertinoSwitch(
                                activeTrackColor: context.theme.accent,
                                value: settings.enableMcpDraftTools,
                                onChanged: (value) {
                                  settings.enableMcpDraftTools = value;
                                },
                              ),
                            ),
                          ),
                          _Divider(),
                          CellItem(
                            title: const Text('Circle Management'),
                            description: const Text('Create and edit circles'),
                            trailing: Transform.scale(
                              scale: 0.7,
                              child: CupertinoSwitch(
                                activeTrackColor: context.theme.accent,
                                value: settings.enableMcpCircleManagement,
                                onChanged: (value) {
                                  settings.enableMcpCircleManagement = value;
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      bottom: 14,
                      top: 10,
                    ),
                    child: Text(
                      '$enabledToolCount/${tools.length} tools enabled. Draft and circle tools require their own switches.',
                      style: TextStyle(
                        color: context.theme.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  for (final group in _toolGroups(tools)) ...[
                    _SectionLabel(title: group.key),
                    CellGroup(
                      padding: const EdgeInsets.only(right: 10, left: 10),
                      cellBackgroundColor:
                          context.theme.settingCellBackgroundColor,
                      child: Column(
                        children: [
                          for (var i = 0; i < group.value.length; i++) ...[
                            _ToolCell(tool: group.value[i]),
                            if (i != group.value.length - 1) _Divider(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolCell extends StatelessWidget {
  const _ToolCell({required this.tool});

  final MixinMcpToolInfo tool;

  @override
  Widget build(BuildContext context) {
    final requiredText = tool.requiredArguments.isEmpty
        ? null
        : 'Required: ${tool.requiredArguments.join(', ')}';

    return CellItem(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tool.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Menlo', fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            tool.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.theme.secondaryText,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          if (requiredText != null) ...[
            const SizedBox(height: 4),
            Text(
              requiredText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.theme.secondaryText,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      description: SizedBox(
        width: 44,
        child: Text(
          tool.enabled ? 'On' : 'Off',
          textAlign: TextAlign.end,
          style: TextStyle(
            color: tool.enabled ? context.theme.accent : context.theme.red,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      trailing: null,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 20, bottom: 8, top: 12),
    child: Text(
      title,
      style: TextStyle(
        color: context.theme.secondaryText,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
    height: 0.5,
    indent: 16,
    endIndent: 16,
    color: context.theme.divider,
  );
}

List<MapEntry<String, List<MixinMcpToolInfo>>> _toolGroups(
  List<MixinMcpToolInfo> tools,
) {
  const scopeOrder = [
    'read',
    'app_control',
    'draft_write',
    'circle_management',
  ];
  return [
    for (final scope in scopeOrder)
      if (tools.any((tool) => tool.scopeKey == scope))
        MapEntry(
          tools.firstWhere((tool) => tool.scopeKey == scope).scopeTitle,
          tools.where((tool) => tool.scopeKey == scope).toList(growable: false),
        ),
  ];
}

String _maskedToken(String? token) {
  if (token == null || token.isEmpty) return 'Unavailable';
  if (token.length <= 8) return '********';
  return '********${token.substring(token.length - 6)}';
}

String _serverStatusText({
  required bool enabled,
  required bool running,
  required Object? error,
}) {
  if (running) return 'Running';
  if (!enabled) return 'Off';
  if (error != null) return 'Error';
  return 'On';
}

const _defaultMcpEndpointText =
    'http://127.0.0.1:${MixinMcpServer.defaultPort}/mcp';
