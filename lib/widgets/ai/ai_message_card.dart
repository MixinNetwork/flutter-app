import 'package:flutter/material.dart'
    hide SelectableRegion, SelectableRegionState;
import 'package:flutter/rendering.dart' show SelectedContent, SelectionStatus;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../ai/model/ai_chat_metadata.dart';
import '../../db/ai_database.dart';
import '../../utils/datetime_format_utils.dart';
import '../../utils/extension/extension.dart';
import '../../utils/platform.dart';
import '../dialog.dart';
import '../markdown.dart';
import '../menu.dart';
import '../message/item/text/selectable.dart';
import '../message/message_bubble.dart';
import '../message/message_datetime_and_status.dart';
import '../message/message_layout.dart';
import '../message/message_style.dart';
import '../qr_code.dart';

const _copyAiMessageTitle = 'Copy AI Message';
const _showAiResponseDetailsTitle = 'AI Response Details';

class AiMessageCard extends StatelessWidget {
  const AiMessageCard({
    required this.message,
    super.key,
    this.prev,
    this.next,
  });

  final AiChatMessage message;
  final AiChatMessage? prev;
  final AiChatMessage? next;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final sameDayPrev = isSameDay(prev?.createdAt, message.createdAt);
    final sameRolePrev = prev?.role == message.role;
    final sameDayNext = isSameDay(next?.createdAt, message.createdAt);
    final sameRoleNext = next?.role == message.role;
    final mergedWithPrev = sameDayPrev && sameRolePrev;
    final mergedWithNext = sameDayNext && sameRoleNext;

    if (isUser) {
      return _AiUserMessageCard(
        message: message,
        mergedWithPrev: mergedWithPrev,
        mergedWithNext: mergedWithNext,
      );
    }

    return _AiResponseMessageCard(
      message: message,
      mergedWithPrev: mergedWithPrev,
    );
  }
}

class _AiUserMessageCard extends StatelessWidget {
  const _AiUserMessageCard({
    required this.message,
    required this.mergedWithPrev,
    required this.mergedWithNext,
  });

  final AiChatMessage message;
  final bool mergedWithPrev;
  final bool mergedWithNext;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 36,
      right: 8,
      top: mergedWithPrev ? 4 : 14,
      bottom: 4,
    ),
    child: Align(
      alignment: Alignment.centerRight,
      child: _AiMessageMenu(
        message: message,
        child: _AiBubble(
          isCurrentUser: true,
          showNip: !mergedWithNext,
          color: context.theme.ai.userBubble,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: MessageLayout(
              spacing: 6,
              content: _AiUserMessageBody(message: message),
              dateAndStatus: MessageMetaRow(dateTime: message.createdAt),
            ),
          ),
        ),
      ),
    ),
  );
}

class _AiResponseMessageCard extends StatefulWidget {
  const _AiResponseMessageCard({
    required this.message,
    required this.mergedWithPrev,
  });

  final AiChatMessage message;
  final bool mergedWithPrev;

  @override
  State<_AiResponseMessageCard> createState() => _AiResponseMessageCardState();
}

class _AiResponseMessageCardState extends State<_AiResponseMessageCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      top: widget.mergedWithPrev ? 6 : 18,
      bottom: 6,
    ),
    child: MouseRegion(
      onEnter: (_) {
        if (!_hovering) setState(() => _hovering = true);
      },
      onExit: (_) {
        if (_hovering) setState(() => _hovering = false);
      },
      child: _AiMessageMenu(
        message: widget.message,
        child: Column(
          spacing: 6,
          children: [
            _AiResponseMessageBody(message: widget.message),
            const SizedBox(height: 4),
            _AiResponseFooter(
              model: widget.message.model,
              dateTime: widget.message.createdAt,
              showModel: _hovering,
            ),
          ],
        ),
      ),
    ),
  );
}

class _AiUserMessageBody extends StatelessWidget {
  const _AiUserMessageBody({required this.message});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) => _AiSelectableText(
    text: _displayText(message),
    style: _aiMessageTextStyle(context, message),
  );
}

class _AiResponseMessageBody extends StatelessWidget {
  const _AiResponseMessageBody({required this.message});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isPendingAssistant =
        message.status == 'pending' && message.content.trim().isEmpty;
    final textStyle = _aiMessageTextStyle(context, message);

    if (isPendingAssistant) {
      return _AiPendingAssistantActivity(message: message, style: textStyle);
    }

    if (message.status == 'error') {
      return _AiSelectableText(
        text: _displayText(message),
        style: textStyle,
      );
    }

    final cacheKey = buildMarkdownCacheKey(
      namespace: 'ai',
      id: message.id,
    );
    return DefaultTextStyle.merge(
      style: textStyle,
      child: MarkdownColumn(
        data: _displayText(message),
        selectable: true,
        cacheKey: cacheKey,
        streaming: message.status == 'pending',
      ),
    );
  }
}

class _AiPendingAssistantActivity extends StatelessWidget {
  const _AiPendingAssistantActivity({
    required this.message,
    required this.style,
  });

  final AiChatMessage message;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final text = _pendingAssistantText(message);
    final color = context.dynamicColor(
      const Color.fromRGBO(131, 145, 158, 1),
      darkColor: const Color.fromRGBO(128, 131, 134, 1),
    );

    return SelectionContainer.disabled(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: style.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiSelectableText extends StatefulWidget {
  const _AiSelectableText({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  State<_AiSelectableText> createState() => _AiSelectableTextState();
}

class _AiSelectableTextState extends State<_AiSelectableText> {
  late final FocusNode _focusNode = FocusNode(
    debugLabel: 'ai_message_selection_focus',
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = Text(widget.text, style: widget.style);
    if (!kPlatformIsDesktop) {
      return child;
    }
    return SelectableRegion(
      focusNode: _focusNode,
      contextMenuBuilder: (context, state) => const SizedBox.shrink(),
      selectionControls: desktopTextSelectionHandleControls,
      child: child,
    );
  }
}

TextStyle _aiMessageTextStyle(BuildContext context, AiChatMessage message) =>
    TextStyle(
      color: message.status == 'error'
          ? context.theme.ai.error
          : context.theme.text,
      fontSize: context.messageStyle.primaryFontSize,
    );

class _AiBubble extends StatelessWidget {
  const _AiBubble({
    required this.child,
    required this.isCurrentUser,
    required this.color,
    required this.showNip,
  });

  final Widget child;
  final bool isCurrentUser;
  final Color color;
  final bool showNip;

  @override
  Widget build(BuildContext context) {
    final clipper = BubbleClipper(
      currentUser: isCurrentUser,
      showNip: showNip,
    );

    return CustomPaint(
      painter: BubblePainter(color: color, clipper: clipper),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: MessageBubbleNipPadding(
          currentUser: isCurrentUser,
          child: child,
        ),
      ),
    );
  }
}

class _AiMessageMenu extends StatelessWidget {
  const _AiMessageMenu({
    required this.message,
    required this.child,
  });

  final AiChatMessage message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final content = _displayText(message);

    return Builder(
      builder: (childContext) => CustomContextMenuWidget(
        hitTestBehavior: HitTestBehavior.translucent,
        desktopMenuWidgetBuilder: CustomDesktopMenuWidgetBuilder(),
        menuProvider: (_) {
          final selectedContent = _findSelectedContent(childContext);
          return MenusWithSeparator(
            childrens: [
              [
                MenuAction(
                  image: MenuImage.icon(Icons.copy),
                  title: context.l10n.copy,
                  callback: () {
                    Clipboard.setData(ClipboardData(text: content));
                  },
                ),
                if (selectedContent != null)
                  MenuAction(
                    image: MenuImage.icon(Icons.copy),
                    title: context.l10n.copySelectedText,
                    callback: () {
                      Clipboard.setData(
                        ClipboardData(text: selectedContent.plainText),
                      );
                    },
                  ),
                if (content.isNotEmpty)
                  MenuAction(
                    image: MenuImage.icon(Icons.qr_code),
                    title: context.l10n.generateQrcode,
                    callback: () => showQrCodeDialog(context, content),
                  ),
              ],
              [
                if (message.role != 'user')
                  MenuAction(
                    image: MenuImage.icon(Icons.info_outline),
                    title: _showAiResponseDetailsTitle,
                    callback: () => _showAiResponseDetails(context, message),
                  ),
                MenuAction(
                  image: MenuImage.icon(Icons.data_object),
                  title: _copyAiMessageTitle,
                  callback: () {
                    Clipboard.setData(ClipboardData(text: message.toString()));
                  },
                ),
              ],
            ],
          );
        },
        child: child,
      ),
    );
  }
}

SelectedContent? _findSelectedContent(BuildContext context) {
  SelectableRegionState? findSelectableRegionState(BuildContext context) {
    if (context is! Element) {
      return null;
    }
    if (context.widget is SelectableRegion) {
      return (context as StatefulElement).state as SelectableRegionState;
    }

    SelectableRegionState? found;
    context.visitChildren((element) {
      if (found != null) return;
      final result = findSelectableRegionState(element);
      if (result != null) {
        found = result;
      }
    });
    return found;
  }

  final selectableRegion = findSelectableRegionState(context);
  final status = selectableRegion?.selectable?.value.status;
  final content = selectableRegion?.selectable?.getSelectedContent();
  if (status == SelectionStatus.uncollapsed && content != null) {
    return content;
  }
  return null;
}

void _showAiResponseDetails(BuildContext context, AiChatMessage message) {
  final rootMeta = decodeAiMessageMetadata(message.metadata);
  final providerMeta = rootMeta['provider'];
  final responseMeta = aiMetadataResponse(message.metadata);
  final usage = responseMeta['usage'];
  final elapsedMs = (responseMeta['elapsedMs'] as num?)?.round();
  final totalTokens = _totalTokens(responseMeta);
  final inputTokens = _usageValue(responseMeta, 'inputTokens');
  final outputTokens = _usageValue(responseMeta, 'outputTokens');
  final promptMessageCount = responseMeta['promptMessageCount'] as num?;
  final toolCount = responseMeta['toolCount'] as num?;
  final outputCharacters = responseMeta['outputCharacters'] as num?;
  final providerType = providerMeta is Map ? providerMeta['type'] : null;
  final providerModel = providerMeta is Map ? providerMeta['model'] : null;
  final model = (message.model?.trim().isNotEmpty ?? false)
      ? message.model!.trim()
      : providerModel is String
      ? providerModel
      : null;
  final completedAt = _formatIsoDateTime(responseMeta['completedAt']);
  final createdAt = DateFormat(
    'yyyy-MM-dd HH:mm:ss',
  ).format(message.createdAt.toLocal());
  final details = <MapEntry<String, String>>[
    MapEntry('Created', createdAt),
    if (completedAt != null) MapEntry('Completed', completedAt),
    MapEntry('Status', message.status),
    if (model != null && model.isNotEmpty) MapEntry('Model', model),
    if (providerType is String && providerType.isNotEmpty)
      MapEntry('Provider', providerType),
    if (elapsedMs != null && elapsedMs > 0)
      MapEntry('Elapsed', _formatElapsed(elapsedMs)),
    if (totalTokens != null && totalTokens > 0)
      MapEntry('Total tokens', _formatFullTokens(totalTokens)),
    if (inputTokens != null && inputTokens > 0)
      MapEntry('Input tokens', _formatFullTokens(inputTokens)),
    if (outputTokens != null && outputTokens > 0)
      MapEntry('Output tokens', _formatFullTokens(outputTokens)),
    if (promptMessageCount != null && promptMessageCount > 0)
      MapEntry('Prompt messages', '${promptMessageCount.round()}'),
    if (toolCount != null && toolCount > 0)
      MapEntry('Tools', '${toolCount.round()}'),
    if (outputCharacters != null && outputCharacters > 0)
      MapEntry('Output chars', '${outputCharacters.round()}'),
    if (usage is Map && usage.isEmpty) const MapEntry('Usage', 'Empty'),
  ];
  final detailsText = details
      .map((entry) => '${entry.key}: ${entry.value}')
      .join('\n');

  showMixinDialog<void>(
    context: context,
    constraints: const BoxConstraints(maxWidth: 420),
    child: Builder(
      builder: (context) => AlertDialogLayout(
        minWidth: 360,
        minHeight: 0,
        titleMarginBottom: 20,
        title: const Text(_showAiResponseDetailsTitle),
        content: DefaultTextStyle.merge(
          style: TextStyle(
            color: context.theme.text,
            fontSize: 13,
            fontWeight: FontWeight.normal,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: details
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 112,
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: context.theme.secondaryText,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SelectableText(
                            entry.value,
                            style: TextStyle(color: context.theme.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        actions: [
          MixinButton(
            backgroundTransparent: true,
            onTap: () {
              Clipboard.setData(ClipboardData(text: detailsText));
            },
            child: Text(context.l10n.copy),
          ),
          MixinButton(
            onTap: () => Navigator.pop(context),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    ),
  );
}

class _AiResponseFooter extends StatelessWidget {
  const _AiResponseFooter({
    required this.model,
    required this.dateTime,
    required this.showModel,
  });

  final String? model;
  final DateTime dateTime;
  final bool showModel;

  @override
  Widget build(BuildContext context) {
    final metaColor = context.dynamicColor(
      const Color.fromRGBO(131, 145, 158, 1),
      darkColor: const Color.fromRGBO(128, 131, 134, 1),
    );
    final textStyle = TextStyle(
      fontSize: context.messageStyle.statusFontSize,
      color: metaColor,
    );
    final dateTimeText = DateFormat.Hm().format(dateTime.toLocal());
    final trimmedModel = model?.trim();
    final text = [
      dateTimeText,
      if (showModel && trimmedModel != null && trimmedModel.isNotEmpty)
        trimmedModel,
    ].join(' · ');

    return SelectionContainer.disabled(
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      ),
    );
  }
}

num? _totalTokens(Map<String, dynamic> responseMeta) =>
    _usageValue(responseMeta, 'totalTokens') ??
    ((_usageValue(responseMeta, 'inputTokens') ?? 0) +
        (_usageValue(responseMeta, 'outputTokens') ?? 0));

num? _usageValue(Map<String, dynamic> responseMeta, String key) {
  final usage = responseMeta['usage'];
  if (usage is Map<String, dynamic>) {
    return usage[key] as num?;
  }
  if (usage is Map) {
    return usage[key] as num?;
  }
  return null;
}

String _formatElapsed(int elapsedMs) {
  if (elapsedMs < 1000) {
    return '${elapsedMs}ms';
  }
  final seconds = elapsedMs / Duration.millisecondsPerSecond;
  return '${seconds.toStringAsFixed(seconds >= 10 ? 0 : 1)}s';
}

String _formatFullTokens(num tokens) =>
    NumberFormat.decimalPattern().format(tokens.round());

String? _formatIsoDateTime(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final dateTime = DateTime.tryParse(value);
  if (dateTime == null) return null;
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime.toLocal());
}

String _displayText(AiChatMessage message) {
  final content = message.content.trim();
  if (content.isNotEmpty) return content;
  if (message.status == 'error') {
    return message.errorText ?? 'Request failed';
  }
  if (message.status == 'pending') return _pendingAssistantText(message);
  return message.errorText ?? 'No response';
}

String _pendingAssistantText(AiChatMessage message) {
  final activeToolName = _activeToolName(message.metadata);
  if (activeToolName != null) {
    return _toolActivityText(activeToolName);
  }
  return 'Thinking...';
}

String? _activeToolName(String? metadata) {
  final events = aiMetadataToolEvents(metadata);
  if (events.isEmpty) {
    return null;
  }

  final finishedToolCallIds = events
      .where((event) => event['type'] == aiToolEventTypeResult)
      .map((event) => event['id'])
      .whereType<String>()
      .toSet();

  for (final event in events.reversed) {
    if (event['type'] != aiToolEventTypeCall) {
      continue;
    }
    final id = event['id'];
    if (id is String && finishedToolCallIds.contains(id)) {
      continue;
    }
    final name = event['name'];
    if (name is String && name.isNotEmpty) {
      return name;
    }
  }
  return null;
}

String _toolActivityText(String toolName) => switch (toolName) {
  'get_conversation_stats' => 'Reading conversation stats...',
  'list_conversation_chunks' => 'Planning conversation read...',
  'read_conversation_chunk' => 'Reading conversation...',
  'search_conversation_messages' => 'Searching conversation...',
  _ => 'Using tool...',
};
